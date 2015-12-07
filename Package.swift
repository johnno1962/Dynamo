
// package for Swift Web Server "Dynamo"

import PackageDescription

let package = Package(
    name: "Dynamo",
    dependencies: [
        .Package(url: "https://github.com/johnno1962/NSLinux.git", majorVersion: 1),
    ]
)
