// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "iOSDevPackage",
    platforms: [
        .iOS(.v13), .watchOS(.v6)
    ],
    products: [
        .library(
            name: "SwiftDevPackage",
            targets: ["SwiftDevPackage"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "SwiftDevPackage",
            dependencies: [
                .target(name: "iOSServices", condition: .when(platforms: [.iOS])),
                .target(name: "DependencyInjection"),
        ]),
        .target(
            name: "iOSServices",
            dependencies: [
                .target(name: "iOSExtensions", condition: .when(platforms: [.iOS])),
                .target(name: "DependencyInjection"),
        ]),
        .target(
            name: "iOSExtensions",
            dependencies: []
        ),
        .target(
            name: "DependencyInjection",
            dependencies: []
        ),
        .testTarget(
            name: "iOSDevPackageTests",
            dependencies: ["SwiftDevPackage"]),
    ]
)
