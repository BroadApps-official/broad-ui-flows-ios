// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "BroadUIFlows",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(name: "BroadUIFlows", targets: ["BroadUIFlows"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/BroadApps-official/broad-core-ios.git",
            from: "2.0.0"
        ),
        .package(
            url: "https://github.com/BroadApps-official/broad-monetization-ios.git",
            from: "4.0.0"
        ),
        .package(
            url: "https://github.com/Swinject/Swinject.git",
            exact: "2.10.0"
        )
    ],
    targets: [
        .target(
            name: "BroadUIFlows",
            dependencies: [
                .product(name: "BroadCore", package: "broad-core-ios"),
                .product(name: "BroadMonetization", package: "broad-monetization-ios"),
                .product(name: "Swinject", package: "Swinject")
            ]
        )
    ],
    swiftLanguageModes: [.v5]
)
