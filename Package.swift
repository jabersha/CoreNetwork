// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CoreNetwork",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "CoreNetwork",
            targets: ["CoreNetwork"]
        ),
    ],
    dependencies: [
        .package(path: "../CoreSecurity")
    ],
    targets: [
        .target(
            name: "CoreNetwork",
            dependencies: ["CoreSecurity"]
        ),
        .testTarget(
            name: "CoreNetworkTests",
            dependencies: ["CoreNetwork", "CoreSecurity"]
        ),
    ]
)
