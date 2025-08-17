// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AKNumericFormatter_Swift",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "AKNumericFormatter_Swift",
            targets: ["AKNumericFormatter_Swift"]
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "AKNumericFormatter_Swift"
        ),
        .testTarget(
            name: "AKNumericFormatter_SwiftTests",
            dependencies: ["AKNumericFormatter_Swift"]
        ),
    ],
    swiftLanguageModes: [.v5],
)
