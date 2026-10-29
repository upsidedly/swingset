// swift-tools-version: 6.0
import PackageDescription
let package = Package(name: "Swingset", platforms: [.macOS(.v14)], products: [.executable(name: "Swingset", targets: ["Swingset"])], targets: [.executableTarget(name: "Swingset")], swiftLanguageModes: [.v6])
