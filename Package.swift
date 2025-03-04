// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DojoTapToPayOniPhoneSDK",
    defaultLocalization: "en",
    platforms: [.iOS(.v12)],
    products: [
        .library(
            name: "DojoTapToPayOniPhoneSDK",
            targets: ["DojoTapToPayOniPhoneSDK"])
    ],
    targets: [
        .binaryTarget(
            name: "DojoTapToPayOniPhoneSDK", 
            path: "DojoTapToPayOniPhoneSDK.xcframework"
        )
    ]
)
