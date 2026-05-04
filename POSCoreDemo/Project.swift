import ProjectDescription

// MARK: - Micro Feature Architecture
//
// Dependency graph (→ means "depends on"):
//
//  App
//   → POSImplementation (Feature/Products, Feature/Cart, Feature/Payment, Feature/Receipt, Core)
//   → CoreSDK
//
//  POSImplementation → [DesignSystem, POSInterface, Domain]
//  DesignSystem      → []                   (pure UI tokens, no business logic)
//  POSInterface      → [Domain]             (protocols only)
//  CoreSDK           → [Domain, POSCore.xcframework]
//  Domain            → []                   (DTOs + SDKClientProtocol)

let project = Project(
    name: "POSCoreDemo",
    targets: [

        // MARK: - App

        .target(
            name: "POSCoreDemo",
            destinations: .iOS,
            product: .app,
            bundleId: "com.example.POSCoreDemo",
            infoPlist: .extendingDefault(with: [
                "UILaunchScreen": [
                    "UIColorName": "",
                    "UIImageName": "",
                ],
                "UISupportedInterfaceOrientations~ipad": [
                    "UIInterfaceOrientationLandscapeLeft",
                    "UIInterfaceOrientationLandscapeRight",
                    "UIInterfaceOrientationPortrait",
                ],
            ]),
            sources: ["App/Sources/**"],
            resources: ["App/Resources/**"],
            dependencies: [
                .target(name: "POSImplementation"),
                .target(name: "CoreSDK"),
            ]
        ),

        // MARK: - Core/DesignSystem
        // Pure design tokens: colors, spacing, radius, view modifiers.
        // No Domain imports — safe to use in any feature without pulling in business logic.

        .target(
            name: "DesignSystem",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.example.DesignSystem",
            sources: ["DesignSystem/Sources/**"],
            dependencies: []
        ),

        // MARK: - Feature/POSInterface
        // Protocols only — no business logic, no xcframework imports.

        .target(
            name: "POSInterface",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.example.POSInterface",
            sources: ["POSInterface/Sources/**"],
            dependencies: [
                .target(name: "Domain"),
            ]
        ),

        // MARK: - Feature/POSImplementation
        // All feature views (Products, Cart, Payment, Receipt) + Core coordinator layer.
        // Internal structure mirrors MFA with subdirectories:
        //   Sources/Feature/Products  — ProductGridView, ProductCard, SearchViewModel
        //   Sources/Feature/Cart      — CartPanelView, CartItemRow
        //   Sources/Feature/Payment   — QRPaymentSheet
        //   Sources/Feature/Receipt   — ReceiptView, HTMLReceiptBuilder
        //   Sources/Core              — POSViewModel, POSSplitView, ContentView

        .target(
            name: "POSImplementation",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.example.POSImplementation",
            sources: ["POSImplementation/Sources/**"],
            dependencies: [
                .target(name: "DesignSystem"),
                .target(name: "POSInterface"),
                .target(name: "Domain"),
            ]
        ),

        .target(
            name: "POSImplementationTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.example.POSImplementationTests",
            sources: ["POSImplementation/Tests/**"],
            dependencies: [
                .target(name: "POSImplementation"),
                .target(name: "POSInterface"),
                .target(name: "Domain"),
            ]
        ),

        // MARK: - Core/Domain
        // SDKClientProtocol, DTOs, state types.
        // No dependencies — the pure abstraction layer.

        .target(
            name: "Domain",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.example.Domain",
            sources: ["Domain/Sources/**"],
            dependencies: []
        ),

        // MARK: - Core/SDK
        // The ONLY module that imports the Go xcframework.
        // Conforms to SDKClientProtocol from Domain.

        .target(
            name: "CoreSDK",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.example.CoreSDK",
            sources: ["CoreSDK/Sources/**"],
            dependencies: [
                .target(name: "Domain"),
                .xcframework(path: "../Frameworks/POSCore.xcframework"),
            ]
        ),
    ]
)
