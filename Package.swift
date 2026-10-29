// swift-tools-version:5.3

import PackageDescription

let release = "https://github.com/seanlaidlaw/FFmpeg-iOS/releases/download/0.1.0"

let package = Package(
    name: "FFmpeg-iOS",
    platforms: [.iOS(.v13)],
    products: [
        .library(
            name: "FFmpeg-iOS",
            targets: [
                "avcodec", "avutil", "avformat", "avfilter", "avdevice", "swscale", "swresample",
                "fftools", "Dummy",
            ]),
    ],
    dependencies: [
        .package(url: "https://github.com/kewlbear/FFmpeg-iOS-Support", from: "0.0.1"),
    ],
    targets: [
        .binaryTarget(name: "avcodec", url: "\(release)/avcodec.zip", checksum: "19f18a120128905a0c07ab63337bb5fea29f439c988e3548fe2ec1d4c126fc1a"),
        .binaryTarget(name: "avutil", url: "\(release)/avutil.zip", checksum: "719f4d62aedc0578d7fa831abd8a5995bb95faa78e41885376054f858a88b3d2"),
        .binaryTarget(name: "avformat", url: "\(release)/avformat.zip", checksum: "afa5987e6c55934012fbacc25aa9d19c23d890fbb88df0afc2e714d4679b9410"),
        .binaryTarget(name: "avfilter", url: "\(release)/avfilter.zip", checksum: "79d1758f76c2ad2d6397699e22323eb1ad4fe5734270fe2d1cd587354828e4b2"),
        .binaryTarget(name: "avdevice", url: "\(release)/avdevice.zip", checksum: "138378a2129b925518886817bb47cbdb99c9d90e769c3b175812d44ba2896422"),
        .binaryTarget(name: "swscale", url: "\(release)/swscale.zip", checksum: "6ea2922208fa40109362aa24a5f5debaaa49a8671751cf1cfc9781a38ac2ead2"),
        .binaryTarget(name: "swresample", url: "\(release)/swresample.zip", checksum: "5e47564fc1f404f1a7d5e45483926df5b4e556dbb9c22ef24e1267452421ac40"),
        .binaryTarget(name: "fftools", url: "\(release)/fftools.zip", checksum: "e7d03deee5d20eeaf8b5673dd4cf288c6b6225787bafc001733959fa56e75fbf"),
        .target(name: "Dummy", dependencies: [
            "fftools",
            "avcodec", "avformat", "avfilter", "avdevice", "avutil", "swscale", "swresample",
            "FFmpeg-iOS-Support",
        ]),
        .testTarget(name: "FFmpeg-iOSTests",
                    dependencies: ["Dummy",]),
    ]
)
