// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MetadataPull",
    products: [
        .executable(name: "mdpull", targets: ["MetadataPull"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "0.0.1")
    ],
    targets: [
        .target(name: "MetadataPull", dependencies: [
            .product(name: "ArgumentParser", package: "swift-argument-parser")
        ])
    ]
)
