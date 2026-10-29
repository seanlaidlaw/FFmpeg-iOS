#!/bin/bash
# Builds ffmpeg as the eight xcframeworks FFmpeg-iOS ships, with the
# configure line its 0.0.10 release was built with, and libfftools
# compiled the way its tool branch compiles it (main and exit renamed
# for FFmpeg-iOS-Support's Hook.m).
#
# Usage: build.sh <ffmpeg source dir> <work dir>
set -euo pipefail

SRC="$(cd "$1" && pwd)"
WORK="$2"
mkdir -p "$WORK"
WORK="$(cd "$WORK" && pwd)"
MIN_IOS=13.0
JOBS=8

# Same as zyuanming/FFmpeg-iOS tool branch, libfftools/Makefile.
FFTOOLS_MAKEFILE="$WORK/libfftools.mk"
cat > "$FFTOOLS_MAKEFILE" <<EOF
include $SRC/Makefile

install-libfftools: install-libs install-headers libfftools.a
	\$(INSTALL) -m 644 libfftools.a "\$(LIBDIR)"
	\$(Q)mkdir -p "\$(INCDIR)/libfftools"
	\$(INSTALL) -m 644 $SRC/fftools/ffmpeg.h "\$(INCDIR)/libfftools"

fftools/ffmpeg.o: CFLAGS += -Dmain="FFmpeg_main(int, char**); extern int FFmpeg_main"

fftools/ffprobe.o: CFLAGS += -Dmain="FFprobe_main(int, char**); extern int FFprobe_main"

LIBFFTOOLS = ffmpeg ffprobe

\$(foreach P,\$(LIBFFTOOLS),\$(eval \$(call DOFFTOOL,\$(P))))

\$(OBJS-ffmpeg) \$(OBJS-ffprobe): CFLAGS += -Dexit=FFmpeg_exit

libfftools.a: \$(OBJS-ffmpeg) \$(OBJS-ffprobe)
	\$(RM) \$@
	\$(AR) \$(ARFLAGS) \$(AR_O) \$^
EOF

clean_env=(env -i HOME="$HOME" PATH="/usr/bin:/bin:/usr/sbin:/sbin" LANG=C)

build_slice() {
    local name="$1" sdk="$2" arch="$3" minflag="$4"; shift 4
    local dir="$WORK/build/$name" prefix="$WORK/install/$name"
    if [ -f "$prefix/lib/libfftools.a" ]; then
        echo "== $name already built"
        return
    fi
    rm -rf "$dir" "$prefix"
    mkdir -p "$dir"
    local flags="-arch $arch $minflag=$MIN_IOS"
    echo "== configure $name"
    (cd "$dir" && "${clean_env[@]}" "$SRC/configure" \
        --prefix="$prefix" \
        --enable-cross-compile \
        --disable-debug \
        --disable-doc \
        --enable-pic \
        --disable-audiotoolbox \
        --disable-sdl2 \
        --disable-libxcb \
        --target-os=darwin \
        --enable-demuxer=matroska \
        --enable-muxer=matroska \
        --enable-decoder=av1 \
        --arch="$arch" \
        --cc="xcrun -sdk $sdk clang" \
        --extra-cflags="$flags" \
        --extra-ldflags="$flags" \
        "$@" > configure.log 2>&1) || { tail -30 "$dir/configure.log"; exit 1; }
    echo "== make $name"
    (cd "$dir" && "${clean_env[@]}" make -j"$JOBS" -f "$FFTOOLS_MAKEFILE" install-libfftools \
        > make.log 2>&1) || { tail -40 "$dir/make.log"; exit 1; }
    rm -rf "$dir"
}

build_slice ios-arm64 iphoneos arm64 -mios-version-min
build_slice sim-arm64 iphonesimulator arm64 -mios-simulator-version-min
build_slice sim-x86_64 iphonesimulator x86_64 -mios-simulator-version-min --disable-x86asm

echo "== xcframeworks"
OUT="$WORK/Frameworks"
rm -rf "$OUT"
mkdir -p "$OUT"
for lib in avcodec avutil avformat avfilter avdevice swscale swresample fftools; do
    staged="$WORK/stage/$lib"
    rm -rf "$staged"
    mkdir -p "$staged/device/Headers" "$staged/sim/Headers"
    cp "$WORK/install/ios-arm64/lib/lib$lib.a" "$staged/device/"
    lipo -create "$WORK/install/sim-arm64/lib/lib$lib.a" "$WORK/install/sim-x86_64/lib/lib$lib.a" \
        -output "$staged/sim/lib$lib.a"
    for slice in device sim; do
        cp -R "$WORK/install/ios-arm64/include/lib$lib" "$staged/$slice/Headers/"
        printf 'module %s {\n    umbrella "."\n    export *\n}' "$lib" \
            > "$staged/$slice/Headers/lib$lib/module.modulemap"
    done
    xcodebuild -create-xcframework \
        -library "$staged/device/lib$lib.a" -headers "$staged/device/Headers" \
        -library "$staged/sim/lib$lib.a" -headers "$staged/sim/Headers" \
        -output "$OUT/$lib.xcframework" > /dev/null
    (cd "$OUT" && zip -qry "$lib.zip" "$lib.xcframework")
    echo "$lib $(swift package compute-checksum "$OUT/$lib.zip")"
done
rm -rf "$WORK/stage"
echo "== done: $OUT"
