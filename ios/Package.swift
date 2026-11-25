// swift-tools-version:5.9
// Pacote só com o núcleo do Milheiro (modelos, catálogo e motor), para rodar
// os testes com `swift test`, sem simulador. O app em si usa o projeto do XcodeGen.
import PackageDescription

let package = Package(
    name: "MilheiroCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "MilheiroCore", targets: ["MilheiroCore"]),
    ],
    targets: [
        .target(name: "MilheiroCore", path: "Shared"),
        .testTarget(name: "MilheiroCoreTests", dependencies: ["MilheiroCore"], path: "Tests"),
    ]
)
