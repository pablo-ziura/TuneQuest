// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "TuneNetwork",
    platforms: [
        .iOS(.v18)
    ],
    products: [
        .library(
            name: "TuneNetwork",
            targets: ["TuneNetwork"]),
    ],
    targets: [
        .target(
            name: "TuneNetwork"),
        .testTarget(
            name: "TuneNetworkTests",
            dependencies: ["TuneNetwork"]
        ),
    ]
)
