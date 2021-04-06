// swift-tools-version:5.0
//
// package for Swift Web Server "Dynamo"

import PackageDescription

let package = Package(
    name: "Dynamo",
    products: [
        .library(name: "Dynamo", targets: ["Dynamo"]),
        .executable(name: "example", targets: ["example"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(name: "example", dependencies: ["Dynamo"], path: "Example"),
        .target(name: "Dynamo", dependencies: [], path: "Sources/"),
    ]
)
