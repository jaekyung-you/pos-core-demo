import SwiftUI
import DesignSystem
import WebKit
import Domain

struct ReceiptView: View {
    @ObservedObject var viewModel: POSViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if let receipt = viewModel.lastReceipt {
                    ReceiptWebView(html: HTMLReceiptBuilder.build(from: receipt)) {
                        closeReceipt()
                    }
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .background(TDS.Color.gray100)
            .navigationTitle("결제 완료")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("확인") { closeReceipt() }
                        .fontWeight(.semibold)
                        .foregroundColor(TDS.Color.blue500)
                }
            }
        }
    }

    private func closeReceipt() {
        viewModel.transactionState = .idle
        dismiss()
    }
}

// MARK: - WKWebView wrapper with JS→Swift bridge

struct ReceiptWebView: UIViewRepresentable {
    let html: String
    let onClose: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onClose: onClose)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        // Register the message handler: JS calls webkit.messageHandlers.posClose.postMessage(...)
        config.userContentController.add(context.coordinator, name: "posClose")

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.scrollView.contentInsetAdjustmentBehavior = .automatic
        webView.isOpaque = false
        webView.backgroundColor = .clear
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        webView.loadHTMLString(html, baseURL: nil)
    }

    static func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) {
        // Prevent retain cycle: remove handler before the view goes away
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "posClose")
    }

    // MARK: - Coordinator (WKScriptMessageHandler)

    final class Coordinator: NSObject, WKScriptMessageHandler {
        let onClose: () -> Void

        init(onClose: @escaping () -> Void) {
            self.onClose = onClose
        }

        func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "posClose" else { return }
            DispatchQueue.main.async { self.onClose() }
        }
    }
}
