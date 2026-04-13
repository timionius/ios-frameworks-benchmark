// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "ios-frameworks-benchmark",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "PixelSamplerSDK",
            targets: ["PixelSamplerSDK"]
        )
    ],
    targets: [
        .target(
            name: "PixelSamplerSDK",
            path: "Sources/PixelSamplerSDK",
            exclude: ["Info.plist"]
        ),
        .testTarget(
            name: "PixelSamplerSDKTests",
            dependencies: ["PixelSamplerSDK"],
            path: "Tests/PixelSamplerSDKTests"
        )
    ]
)