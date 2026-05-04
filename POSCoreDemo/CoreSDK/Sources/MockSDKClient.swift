import Foundation
import Domain

// Mock implementation — will be replaced with real Go xcframework in Week 2.
public final class MockSDKClient: SDKClientProtocol {

    public private(set) var transactionState: TransactionState = .idle
    public private(set) var hasPendingTransaction: Bool = false
    private var lastReceipt: POSReceipt?
    private var runningTotal: Int = 0

    public init() {}

    public func charge(amount: Int, method: PaymentMethod, items: [CartItem]) async throws {
        transactionState = .processing
        try await Task.sleep(nanoseconds: 1_200_000_000) // 1.2s simulated delay

        // Simulate occasional failure for demo
        let success = Bool.random() ? true : (Int.random(in: 1...10) > 2)
        if success {
            transactionState = .success
            runningTotal += amount
            lastReceipt = POSReceipt(
                items: items.map { ReceiptItem(name: $0.name, qty: $0.qty, price: $0.price) },
                total: amount,
                discount: 0,
                vat: Int(Double(amount) * 0.1 / 1.1),
                method: method.rawValue,
                timestamp: ISO8601DateFormatter().string(from: Date())
            )
        } else {
            transactionState = .failure
            throw SDKError.paymentFailed
        }
    }

    public func getReceipt() -> POSReceipt? {
        lastReceipt
    }

    public func getTodayTotal() -> Int {
        runningTotal
    }
}

public enum SDKError: LocalizedError {
    case paymentFailed

    public var errorDescription: String? {
        switch self {
        case .paymentFailed: return "결제에 실패했습니다. 다시 시도해주세요."
        }
    }
}
