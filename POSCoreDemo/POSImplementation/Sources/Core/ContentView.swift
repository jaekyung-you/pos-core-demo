import SwiftUI
import Domain

public struct ContentView: View {
    @ObservedObject var viewModel: POSViewModel

    public init(viewModel: POSViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        POSSplitView(viewModel: viewModel)
            .onAppear { viewModel.startPolling() }
            .onDisappear { viewModel.stopPolling() }
    }
}
