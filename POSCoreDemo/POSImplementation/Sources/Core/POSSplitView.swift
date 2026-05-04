import SwiftUI
import DesignSystem
import Domain

// iPad (regular) → 2:1 split view, both panels always visible.
// iPhone (compact) → navigation stack.
struct POSSplitView: View {
    @ObservedObject var viewModel: POSViewModel
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        if sizeClass == .regular {
            iPadLayout
        } else {
            iPhoneLayout
        }
    }

    // MARK: - iPad Layout

    private var iPadLayout: some View {
        HStack(spacing: 0) {
            ProductGridView(viewModel: viewModel)
                .frame(maxWidth: .infinity)

            Divider()

            CartPanelView(viewModel: viewModel)
                .frame(width: 400)
        }
        .background(TDS.Color.gray100)
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: - iPhone Layout

    private var iPhoneLayout: some View {
        NavigationStack {
            ProductGridView(viewModel: viewModel)
                .navigationTitle("POS")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        NavigationLink {
                            CartPanelView(viewModel: viewModel)
                                .navigationTitle("장바구니")
                        } label: {
                            cartBadge
                        }
                    }
                }
        }
    }

    private var cartBadge: some View {
        ZStack(alignment: .topTrailing) {
            Image(systemName: "cart")
                .foregroundColor(TDS.Color.blue500)
            if !viewModel.cartItems.isEmpty {
                Text("\(viewModel.cartItems.reduce(0) { $0 + $1.qty })")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(3)
                    .background(TDS.Color.blue500)
                    .clipShape(Circle())
                    .offset(x: 8, y: -8)
            }
        }
    }
}
