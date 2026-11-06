// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "MySoKit",
    platforms: [.iOS(.v17), .macOS(.v13), .watchOS(.v9), .tvOS(.v17)],
    products: [
        .library(
            name: "MySoKit",
            targets: ["MySoKit"]
        ),
        .library(
            name: "MyDataCrypto",
            targets: ["MyDataCrypto"]
        ),
        .library(
            name: "MySoContra",
            targets: ["MySoContra"]
        ),
        .library(
            name: "MySoMLS",
            targets: ["MySoMLS"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/MarcoDotIO/UInt256.git", from: "1.0.0"),
        .package(url: "https://github.com/pebble8888/ed25519swift.git", from: "1.2.7"),
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", from: "5.0.2"),
        .package(url: "https://github.com/tesseract-one/Blake2.swift.git", from: "0.2.0"),
        .package(url: "https://github.com/MarcoDotIO/AnyCodable", from: "1.0.0"),
        .package(url: "https://github.com/tesseract-one/Bip39.swift.git", from: "0.1.1"),
        .package(url: "https://github.com/auth0/JWTDecode.swift", from: "3.1.0"),
        .package(url: "https://github.com/attaswift/BigInt.git", from: "5.3.0"),
        .package(url: "https://github.com/apollographql/apollo-ios.git", exact: "1.17.0"),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", from: "1.8.0"),
    ],
    targets: [
        .target(
            name: "secp256k1myso"
        ),
        .target(
            name: "MySoKit",
            dependencies: [
                .product(name: "BigInt", package: "BigInt"),
                .product(name: "UInt256", package: "UInt256"),
                .product(name: "ed25519swift", package: "ed25519swift"),
                .product(name: "SwiftyJSON", package: "swiftyjson"),
                .product(name: "Blake2", package: "Blake2.swift"),
                .product(name: "AnyCodable", package: "AnyCodable"),
                .product(name: "Bip39", package: "Bip39.swift"),
                .product(name: "JWTDecode", package: "JWTDecode.swift"),
                .product(name: "Apollo", package: "apollo-ios"),
                "secp256k1myso"
            ]
        ),
        .target(
            name: "CBlst",
            path: "Sources/CBlst",
            exclude: [
                "src",
                "build/bindings_trim.pl",
                "build/refresh.sh",
                "build/srcroot.go",
                "build/cheri",
                "build/coff",
                "build/win64"
            ],
            sources: [
                "blst_amalg.c",
                "build/assembly.S"
            ],
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("src"),
                .headerSearchPath("include"),
                .headerSearchPath("build"),
                .define("__BLST_PORTABLE__"),
                .unsafeFlags(["-Wno-unused-function", "-O2", "-fno-builtin"])
            ]
        ),
        .target(
            name: "MyDataCrypto",
            dependencies: [
                "CBlst",
                .product(name: "CryptoSwift", package: "CryptoSwift")
            ],
            path: "Sources/MyDataCrypto",
            exclude: ["README.md"],
            resources: [
                .copy("Fixtures")
            ]
        ),
        .testTarget(
            name: "MySoKitTests",
            dependencies: ["MySoKit"],
            path: "Tests",
            exclude: ["MyDataCryptoTests"],
            resources: [
                .copy("Resources/coin-metadata.json"),
                .copy("Resources/display-test.json"),
                .copy("Resources/dynamic-fields.json"),
                .copy("Resources/entry-point-types.json"),
                .copy("Resources/entry-point-vector.json"),
                .copy("Resources/hero.json"),
                .copy("Resources/id-entry-args.json"),
                .copy("Resources/kiosk.json"),
                .copy("Resources/serializer.json"),
                .copy("Resources/serializer-upgrade.json")
            ]
        ),
        .binaryTarget(
            name: "MySoContraFFI",
            url: "https://pub-1f3749a8084a44c3abbd97a4875268a1.r2.dev/MySoContraFFI.xcframework.zip",
            checksum: "653727eb38db4d96257c0314aa4996c27579cb1285a4bb80cddd16cb3b086bcf"
        ),
        .target(
            name: "MySoContra",
            dependencies: ["MySoContraFFI"],
            path: "Sources/MySoContra"
        ),
        // MLS (E2EE M6): OpenMLS via myso-messaging-stack/mls. Built locally by
        // `mls/scripts/build-xcframework.sh`; release builds switch to a hosted zip + checksum.
        .binaryTarget(
            name: "MySoMLSFFI",
            path: "Frameworks/MySoMLSFFI.xcframework"
        ),
        .target(
            name: "MySoMLS",
            dependencies: ["MySoMLSFFI"],
            path: "Sources/MySoMLS"
        ),
        .testTarget(
            name: "MyDataCryptoTests",
            dependencies: ["MyDataCrypto"],
            path: "Tests/MyDataCryptoTests",
            resources: [
                .copy("Fixtures")
            ]
        ),
    ]
)
