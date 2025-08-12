// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Amplitude-E2E-Test",
    platforms: [
        .iOS(.v14),
        .macOS(.v10_13),
        .tvOS(.v12),
        .watchOS(.v4)
    ],
    products: [],
    dependencies: [
        .package(path: "../AmplitudeCore-Swift"),
    ],
    targets: [
        .testTarget(
            name: "CoreRemoteConfigSDKTests",
            dependencies: [
                .product(name: "AmplitudeCore", package: "AmplitudeCore-Swift")
            ]
        )
    ]
)

