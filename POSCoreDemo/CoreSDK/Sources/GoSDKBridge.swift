import Foundation
import Domain
import POSCore

// Bridge spike: verifies the gomobile xcframework is wired correctly.
// PosAdd(3, 4) == 7 proves the Go-Swift boundary is working.
public enum GoSDKBridge {
    public static func validateBridge() -> Bool {
        return PosAdd(3, 4) == 7
    }

    public static func add(_ a: Int64, _ b: Int64) -> Int64 {
        return PosAdd(a, b)
    }
}

// Real SDK implementation backed by the Go xcframework.
// Conforms to SDKClientProtocol so App can inject it via the same interface as MockSDKClient.
public final class SDKClient: SDKClientProtocol {

    public private(set) var transactionState: TransactionState = .idle

    public var hasPendingTransaction: Bool {
        PosCheckPendingTransaction()
    }

    public init() {
        PosInit()
    }

    public func charge(amount: Int, method: PaymentMethod, items: [CartItem]) async throws {
        transactionState = .processing

        let itemDicts: [[String: Any]] = items.map {
            ["name": $0.name, "qty": $0.qty, "price": $0.price]
        }
        let itemsJSON = (try? JSONSerialization.data(withJSONObject: itemDicts))
            .flatMap { String(data: $0, encoding: .utf8) } ?? "[]"

        let chargeAmount = Int64(amount)
        let chargeMethod = method.rawValue

        let success = try await Task.detached(priority: .userInitiated) { () throws -> Bool in
            var retVal: ObjCBool = false
            var nsErr: NSError?
            PosCharge(chargeAmount, chargeMethod, itemsJSON, &retVal, &nsErr)
            if let e = nsErr { throw e }
            return retVal.boolValue
        }.value

        transactionState = success ? .success : .failure
        if !success {
            throw SDKError.paymentFailed
        }
    }

    public func getReceipt() -> POSReceipt? {
        var nsErr: NSError?
        let json = PosGetReceipt(&nsErr)
        guard nsErr == nil, !json.isEmpty else { return nil }
        return try? JSONDecoder().decode(POSReceipt.self, from: Data(json.utf8))
    }

    public func getTodayTotal() -> Int {
        Int(PosGetTodayTotal())
    }
}
