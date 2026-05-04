import Foundation
import Domain
import POSInterface

@MainActor
public final class POSViewModel: ObservableObject {

    @Published public var cartItems: [CartItem] = []
    @Published public var selectedPaymentMethod: PaymentMethod = .card
    @Published public var transactionState: TransactionState = .idle
    @Published public var todayTotal: Int = 0
    @Published public var hasPendingTransaction: Bool = false
    @Published public var discountRate: Double = 0
    @Published public var lastReceipt: POSReceipt? = nil

    private let sdk: SDKClientProtocol
    private var pollingTask: Task<Void, Never>?

    public init(sdk: SDKClientProtocol) {
        self.sdk = sdk
    }

    // MARK: - Computed

    public var subtotal: Int {
        cartItems.reduce(0) { $0 + $1.price * $1.qty }
    }

    public var discountAmount: Int {
        Int(Double(subtotal) * discountRate)
    }

    public var vatAmount: Int {
        let discounted = subtotal - discountAmount
        return Int(Double(discounted) * 0.1 / 1.1)
    }

    public var totalAmount: Int {
        subtotal - discountAmount
    }

    // MARK: - Cart

    public func addProduct(_ product: Product) {
        if let idx = cartItems.firstIndex(where: { $0.name == product.name }) {
            let item = cartItems[idx]
            cartItems[idx] = CartItem(name: item.name, qty: item.qty + 1, price: item.price)
        } else {
            cartItems.append(CartItem(name: product.name, qty: 1, price: product.price))
        }
    }

    public func updateQuantity(name: String, delta: Int) {
        guard let idx = cartItems.firstIndex(where: { $0.name == name }) else { return }
        let newQty = cartItems[idx].qty + delta
        if newQty <= 0 {
            cartItems.remove(at: idx)
        } else {
            let item = cartItems[idx]
            cartItems[idx] = CartItem(name: item.name, qty: newQty, price: item.price)
        }
    }

    public func applyDiscount(code: String) {
        discountRate = code.uppercased() == "TOSS10" ? 0.1 : 0
    }

    // MARK: - Payment

    public func pay() async {
        guard !cartItems.isEmpty else { return }
        transactionState = .processing
        do {
            try await sdk.charge(amount: totalAmount, method: selectedPaymentMethod, items: cartItems)
            transactionState = .success
            lastReceipt = sdk.getReceipt()
            cartItems = []
        } catch {
            transactionState = .failure
        }
    }

    // MARK: - Today's Total Polling

    public func startPolling() {
        pollingTask = Task {
            while !Task.isCancelled {
                todayTotal = sdk.getTodayTotal()
                try? await Task.sleep(nanoseconds: 500_000_000)
            }
        }
    }

    public func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }
}

