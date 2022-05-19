// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "tuist-cli",
    platforms: [.macOS(.v11)],
    products: [
        .executable(name: "tuist-cli", targets: ["CLI"]),
        .executable(name: "tuist-ci", targets: ["CI"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/objecthub/swift-commandlinekit.git", from: "0.3.0")
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .executableTarget(
            name: "CLI",
            dependencies: [
                .product(name: "CommandLineKit", package: "swift-commandlinekit"),
                "RunShell"
            ]
        ),
        .executableTarget(
            name: "CI",
            dependencies: ["RunShell"]),
        .target(name: "RunShell")
    ]
)
