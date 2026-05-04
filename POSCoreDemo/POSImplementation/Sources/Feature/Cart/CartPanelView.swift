import SwiftUI
import DesignSystem
import Domain

struct CartPanelView: View {
    @ObservedObject var viewModel: POSViewModel
    @State private var discountCode: String = ""
    @State private var showReceipt: Bool = false
    @State private var showError: Bool = false
    @State private var showQRSheet: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            cartHeader
            Divider()

            if viewModel.cartItems.isEmpty {
                emptyCart
            } else {
                cartItemsList
            }

            Divider()
            summarySection
            Divider()
            paymentMethodSection
            ctaSection
        }
        .background(TDS.Color.white)
        .onChange(of: viewModel.transactionState) { _, state in
            if state == .success { showReceipt = true }
            if state == .failure { showError = true }
        }
        .sheet(isPresented: $showReceipt) {
            ReceiptView(viewModel: viewModel)
        }
        .sheet(isPresented: $showQRSheet) {
            QRPaymentSheet(amount: viewModel.totalAmount) {
                await viewModel.pay()
            }
        }
        .overlay(alignment: .top) {
            if showError {
                errorBanner
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation { showError = false }
                        }
                    }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showError)
    }

    // MARK: - Header (Today's Total)

    private var cartHeader: some View {
        HStack {
            Text("장바구니")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(TDS.Color.gray900)

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("TODAY")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(TDS.Color.blue500)
                Text("₩\(viewModel.todayTotal.formatted())")
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundColor(TDS.Color.blue500)
                    .contentTransition(.numericText())
                    .animation(.spring(duration: 0.4), value: viewModel.todayTotal)
            }
            .padding(.horizontal, TDS.Spacing.md)
            .padding(.vertical, TDS.Spacing.sm)
            .background(TDS.Color.blue50)
            .clipShape(RoundedRectangle(cornerRadius: TDS.Radius.badge))
        }
        .padding(.horizontal, TDS.Spacing.xl)
        .padding(.vertical, TDS.Spacing.lg)
    }

    // MARK: - Empty State

    private var emptyCart: some View {
        VStack(spacing: TDS.Spacing.sm) {
            Image(systemName: "cart")
                .font(.system(size: 32))
                .foregroundColor(TDS.Color.gray200)
            Text("상품을 선택해주세요")
                .font(.system(size: 14))
                .foregroundColor(TDS.Color.gray400)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Cart Items

    private var cartItemsList: some View {
        ScrollView {
            VStack(spacing: TDS.Spacing.sm) {
                ForEach(viewModel.cartItems, id: \.name) { item in
                    CartItemRow(item: item) { delta in
                        viewModel.updateQuantity(name: item.name, delta: delta)
                    }
                }
            }
            .padding(.horizontal, TDS.Spacing.xl)
            .padding(.vertical, TDS.Spacing.md)
        }
    }

    // MARK: - Summary

    private var summarySection: some View {
        VStack(spacing: TDS.Spacing.sm) {
            discountRow
            VStack(spacing: TDS.Spacing.xs) {
                summaryRow("소계", amount: viewModel.subtotal)
                if viewModel.discountAmount > 0 {
                    HStack {
                        Text("할인 (\(Int(viewModel.discountRate * 100))%)")
                            .font(.system(size: 14))
                            .foregroundColor(TDS.Color.red500)
                        Spacer()
                        Text("−₩\(viewModel.discountAmount.formatted())")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(TDS.Color.red500)
                    }
                }
                summaryRow("부가세 (VAT 10%)", amount: viewModel.vatAmount)
                Divider().padding(.vertical, TDS.Spacing.xs)
                HStack {
                    Text("합계")
                        .font(.system(size: 17, weight: .heavy))
                        .foregroundColor(TDS.Color.gray900)
                    Spacer()
                    Text("₩\(viewModel.totalAmount.formatted())")
                        .font(.system(size: 17, weight: .heavy))
                        .foregroundColor(TDS.Color.gray900)
                }
            }
        }
        .padding(.horizontal, TDS.Spacing.xl)
        .padding(.vertical, TDS.Spacing.md)
    }

    private var discountRow: some View {
        HStack(spacing: TDS.Spacing.sm) {
            TextField("할인 코드 입력", text: $discountCode)
                .font(.system(size: 14))
                .padding(.horizontal, TDS.Spacing.lg)
                .padding(.vertical, TDS.Spacing.md)
                .background(TDS.Color.gray50)
                .clipShape(RoundedRectangle(cornerRadius: TDS.Radius.input))
                .overlay(
                    RoundedRectangle(cornerRadius: TDS.Radius.input)
                        .stroke(TDS.Color.gray200, lineWidth: 1.5)
                )

            Button {
                viewModel.applyDiscount(code: discountCode)
            } label: {
                Text("적용")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, TDS.Spacing.xl)
                    .padding(.vertical, TDS.Spacing.md)
                    .background(TDS.Color.blue500)
                    .clipShape(RoundedRectangle(cornerRadius: TDS.Radius.input))
            }
        }
    }

    private func summaryRow(_ label: String, amount: Int) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(TDS.Color.gray700)
            Spacer()
            Text("₩\(amount.formatted())")
                .font(.system(size: 14))
                .foregroundColor(TDS.Color.gray700)
        }
    }

    // MARK: - Payment Method

    private var paymentMethodSection: some View {
        VStack(alignment: .leading, spacing: TDS.Spacing.sm) {
            Text("결제 수단")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(TDS.Color.gray400)
                .textCase(.uppercase)
                .tracking(0.5)

            HStack(spacing: TDS.Spacing.sm) {
                ForEach(PaymentMethod.allCases, id: \.self) { method in
                    paymentTab(method)
                }
            }
        }
        .padding(.horizontal, TDS.Spacing.xl)
        .padding(.vertical, TDS.Spacing.md)
    }

    private func paymentTab(_ method: PaymentMethod) -> some View {
        let isSelected = viewModel.selectedPaymentMethod == method
        return Button {
            viewModel.selectedPaymentMethod = method
        } label: {
            VStack(spacing: TDS.Spacing.xs) {
                Image(systemName: method.icon)
                    .font(.system(size: 18))
                Text(method.displayName)
                    .font(.system(size: 12, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, TDS.Spacing.md)
            .foregroundColor(isSelected ? TDS.Color.blue500 : TDS.Color.gray700)
            .background(isSelected ? TDS.Color.blue50 : TDS.Color.gray50)
            .clipShape(RoundedRectangle(cornerRadius: TDS.Radius.input))
            .overlay(
                RoundedRectangle(cornerRadius: TDS.Radius.input)
                    .stroke(isSelected ? TDS.Color.blue500 : TDS.Color.gray200, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - CTA

    private var ctaSection: some View {
        let isProcessing = viewModel.transactionState == .processing
        let isEmpty = viewModel.cartItems.isEmpty

        return Button {
            if viewModel.selectedPaymentMethod == .qr {
                showQRSheet = true
            } else {
                Task { await viewModel.pay() }
            }
        } label: {
            HStack(spacing: TDS.Spacing.sm) {
                if isProcessing {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                        .scaleEffect(0.8)
                    Text("처리 중...")
                } else {
                    Text("결제하기")
                    Text("Go SDK")
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.horizontal, TDS.Spacing.sm)
                        .padding(.vertical, TDS.Spacing.xs)
                        .background(.white.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: TDS.Radius.tag))
                }
            }
            .font(.system(size: 17, weight: .bold))
            .foregroundColor(isEmpty ? TDS.Color.gray400 : .white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(isEmpty ? TDS.Color.gray200 : TDS.Color.blue500)
            .clipShape(RoundedRectangle(cornerRadius: TDS.Radius.button))
        }
        .disabled(isEmpty || isProcessing)
        .padding(.horizontal, TDS.Spacing.xl)
        .padding(.bottom, TDS.Spacing.xl)
        .padding(.top, TDS.Spacing.md)
        .animation(.easeInOut(duration: 0.2), value: isProcessing)
    }

    // MARK: - Error Banner

    private var errorBanner: some View {
        HStack(spacing: TDS.Spacing.sm) {
            Image(systemName: "exclamationmark.circle.fill")
            Text("결제 실패. 다시 시도하세요.")
                .font(.system(size: 14, weight: .semibold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, TDS.Spacing.xl)
        .padding(.vertical, TDS.Spacing.md)
        .background(TDS.Color.red500)
        .clipShape(RoundedRectangle(cornerRadius: TDS.Radius.badge))
        .padding(.top, TDS.Spacing.md)
        .padding(.horizontal, TDS.Spacing.xl)
    }
}

// MARK: - PaymentMethod extensions

extension PaymentMethod: CaseIterable {
    public static var allCases: [PaymentMethod] { [.card, .qr, .cash] }

    var displayName: String {
        switch self {
        case .card: return "카드"
        case .qr:   return "QR"
        case .cash: return "현금"
        }
    }

    var icon: String {
        switch self {
        case .card: return "creditcard.fill"
        case .qr:   return "qrcode"
        case .cash: return "banknote.fill"
        }
    }
}
