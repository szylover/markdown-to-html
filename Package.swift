// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "markdown-to-html",
    products: [
        .library(
            name: "MarkdownToHTMLCore",
            targets: ["MarkdownToHTMLCore"]
        ),
        .executable(
            name: "markdown-to-html",
            targets: ["markdown-to-html"]
        ),
    ],
    targets: [
        .target(
            name: "MarkdownToHTMLCore"
        ),
        .executableTarget(
            name: "markdown-to-html",
            dependencies: ["MarkdownToHTMLCore"]
        ),
        .testTarget(
            name: "markdown-to-htmlTests",
            dependencies: ["MarkdownToHTMLCore"]
        ),
    ]
)
