// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "ForgeLog",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
    ],
    products: [
        .library(name: "ForgeLog", targets: ["ForgeLog"]),
    ],
    dependencies: [
        .package(url: "https://github.com/stefanprojchev/ForgeCore.git", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "ForgeLog",
            dependencies: [
                .product(name: "ForgeCore", package: "ForgeCore"),
            ]
        ),
        .testTarget(
            name: "ForgeLogTests",
            dependencies: ["ForgeLog"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
