import Foundation
import Domain

public protocol POSViewModelProtocol: ObservableObject {
    var cartItems: [CartItem] { get }
    var totalAmount: Int { get }
    var discountAmount: Int { get }
    var vatAmount: Int { get }
    var selectedPaymentMethod: PaymentMethod { get set }
    var transactionState: TransactionState { get }
    var todayTotal: Int { get }
    var hasPendingTransaction: Bool { get }

    func addProduct(_ product: Product)
    func removeProduct(_ product: Product)
    func updateQuantity(_ product: Product, qty: Int)
    func pay() async
    func applyDiscount(code: String)
}

public struct Product: Identifiable, Hashable {
    public let id: UUID
    public let name: String
    public let price: Int
    public let category: String

    public init(id: UUID = UUID(), name: String, price: Int, category: String) {
        self.id = id
        self.name = name
        self.price = price
        self.category = category
    }
}
