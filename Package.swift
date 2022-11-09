// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "XcapKit",
    platforms: [.iOS(.v11), .macOS(.v11)],
    products: [
        .library(name: "XcapKit", targets: ["XcapKit"]),
    ],
    targets: [
        .target(name: "XcapKit"),
        .testTarget(name: "XcapKitTests", dependencies: ["XcapKit"]),
    ]
)
