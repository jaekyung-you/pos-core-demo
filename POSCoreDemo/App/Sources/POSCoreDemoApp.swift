import SwiftUI
import POSImplementation
import CoreSDK

// App is the only place that imports CoreSDK.
// It creates the SDK client and injects it — POSImplementation never sees CoreSDK.
@main
struct POSCoreDemoApp: App {
    private let sdk = SDKClient()

    init() {
        let bridgeOk = GoSDKBridge.validateBridge()
        print("🌉 Go bridge: PosAdd(3,4) == 7 →", bridgeOk)
    }

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: POSViewModel(sdk: sdk))
        }
    }
}
