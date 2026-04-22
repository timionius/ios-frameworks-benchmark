// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "ios-frameworks-benchmark",
    platforms: [
        .iOS(.v16),
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
            swiftSettings: [
                .define("PIXEL_SAMPLER_LOGGING", .when(configuration: .release))
            ]
        ),
        .testTarget(
            name: "PixelSamplerSDKTests",
            dependencies: ["PixelSamplerSDK"],
            path: "Tests/PixelSamplerSDKTests"
        )
    ]
)
