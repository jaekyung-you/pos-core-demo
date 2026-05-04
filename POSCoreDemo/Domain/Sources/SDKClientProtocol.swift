import Foundation

// MARK: - Types

public enum PaymentMethod: String {
    case card = "card"
    case qr = "qr"
    case cash = "cash"
}

public enum TransactionState {
    case idle
    case processing
    case success
    case failure
    case pending
}

public struct CartItem {
    public let name: String
    public let qty: Int
    public let price: Int

    public init(name: String, qty: Int, price: Int) {
        self.name = name
        self.qty = qty
        self.price = price
    }
}

public struct POSReceipt: Codable {
    public let items: [ReceiptItem]
    public let total: Int
    public let discount: Int
    public let vat: Int
    public let method: String
    public let timestamp: String

    public init(items: [ReceiptItem], total: Int, discount: Int, vat: Int, method: String, timestamp: String) {
        self.items = items
        self.total = total
        self.discount = discount
        self.vat = vat
        self.method = method
        self.timestamp = timestamp
    }
}

public struct ReceiptItem: Codable {
    public let name: String
    public let qty: Int
    public let price: Int

    public init(name: String, qty: Int, price: Int) {
        self.name = name
        self.qty = qty
        self.price = price
    }
}

// MARK: - Protocol

public protocol SDKClientProtocol {
    func charge(amount: Int, method: PaymentMethod, items: [CartItem]) async throws
    func getReceipt() -> POSReceipt?
    func getTodayTotal() -> Int
    var hasPendingTransaction: Bool { get }
    var transactionState: TransactionState { get }
}
