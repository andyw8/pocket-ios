// swift-tools-version:5.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PocketPackage",
    platforms: [.iOS("15"), .macOS("11")],
    products: [
        .executable(name: "ApolloCodegen", targets: ["ApolloCodegen"])
    ],
    dependencies: [
        .package(name: "Apollo", url: "https://github.com/apollographql/apollo-ios.git", .upToNextMajor(from: "0.48.0")),
        .package(name: "swift-argument-parser", url: "https://github.com/apple/swift-argument-parser.git", .upToNextMinor(from: "0.3.0"))
    ],
    targets: [
        .executableTarget(
            name: "ApolloCodegen",
            dependencies: [
                .product(name: "ApolloCodegenLib", package: "Apollo"),
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        )
    ]
)
