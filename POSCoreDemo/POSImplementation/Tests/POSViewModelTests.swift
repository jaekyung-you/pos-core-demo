import XCTest
import Domain
import POSInterface
@testable import POSImplementation

// MARK: - Cart Tests

final class CartTests: XCTestCase {

    @MainActor func test_addProduct_appendsToCart() {
        let vm = makeVM()
        vm.addProduct(americano)
        XCTAssertEqual(vm.cartItems.count, 1)
        XCTAssertEqual(vm.cartItems[0].name, "아메리카노")
        XCTAssertEqual(vm.cartItems[0].qty, 1)
    }

    @MainActor func test_addSameProduct_incrementsQty() {
        let vm = makeVM()
        vm.addProduct(americano)
        vm.addProduct(americano)
        XCTAssertEqual(vm.cartItems.count, 1)
        XCTAssertEqual(vm.cartItems[0].qty, 2)
    }

    @MainActor func test_addDifferentProducts_appendsBoth() {
        let vm = makeVM()
        vm.addProduct(americano)
        vm.addProduct(muffin)
        XCTAssertEqual(vm.cartItems.count, 2)
    }

    @MainActor func test_updateQuantity_increment() {
        let vm = makeVM()
        vm.addProduct(americano)
        vm.updateQuantity(name: "아메리카노", delta: 2)
        XCTAssertEqual(vm.cartItems[0].qty, 3)
    }

    @MainActor func test_updateQuantity_decrement() {
        let vm = makeVM()
        vm.addProduct(americano)
        vm.addProduct(americano)
        vm.updateQuantity(name: "아메리카노", delta: -1)
        XCTAssertEqual(vm.cartItems[0].qty, 1)
    }

    @MainActor func test_updateQuantity_toZero_removesItem() {
        let vm = makeVM()
        vm.addProduct(americano)
        vm.updateQuantity(name: "아메리카노", delta: -1)
        XCTAssertTrue(vm.cartItems.isEmpty)
    }

    @MainActor func test_updateQuantity_belowZero_removesItem() {
        let vm = makeVM()
        vm.addProduct(americano)
        vm.updateQuantity(name: "아메리카노", delta: -5)
        XCTAssertTrue(vm.cartItems.isEmpty)
    }

    @MainActor func test_updateQuantity_unknownName_doesNothing() {
        let vm = makeVM()
        vm.addProduct(americano)
        vm.updateQuantity(name: "없는상품", delta: 1)
        XCTAssertEqual(vm.cartItems.count, 1)
    }
}

// MARK: - Price Calculation Tests

final class PriceCalculationTests: XCTestCase {

    @MainActor func test_subtotal_sumOfAllItems() {
        let vm = makeVM()
        vm.addProduct(americano) // 4500
        vm.addProduct(americano) // +4500 = 9000
        vm.addProduct(muffin)    // +3800 = 12800
        XCTAssertEqual(vm.subtotal, 12800)
    }

    @MainActor func test_subtotal_emptyCart_isZero() {
        let vm = makeVM()
        XCTAssertEqual(vm.subtotal, 0)
    }

    @MainActor func test_discountAmount_withValidCode() {
        let vm = makeVM()
        vm.addProduct(americano) // 4500
        vm.applyDiscount(code: "TOSS10")
        XCTAssertEqual(vm.discountAmount, 450) // 10% of 4500
    }

    @MainActor func test_discountAmount_withNoCode_isZero() {
        let vm = makeVM()
        vm.addProduct(americano)
        XCTAssertEqual(vm.discountAmount, 0)
    }

    @MainActor func test_vatAmount_isAppliedAfterDiscount() {
        let vm = makeVM()
        // subtotal = 11000, discount 10% = 1100, discounted = 9900
        // VAT = 9900 * 0.1 / 1.1 = 900
        vm.addProduct(Product(name: "테스트", price: 11000, category: "기타"))
        vm.applyDiscount(code: "TOSS10")
        XCTAssertEqual(vm.vatAmount, 899) // Int(9900 * 0.1 / 1.1) truncates to 899
    }

    @MainActor func test_totalAmount_subtractDiscount() {
        let vm = makeVM()
        vm.addProduct(americano) // 4500
        vm.applyDiscount(code: "TOSS10") // -450
        XCTAssertEqual(vm.totalAmount, 4050)
    }

    @MainActor func test_totalAmount_noDiscount_equalSubtotal() {
        let vm = makeVM()
        vm.addProduct(americano)
        XCTAssertEqual(vm.totalAmount, vm.subtotal)
    }
}

// MARK: - Discount Tests

final class DiscountTests: XCTestCase {

    @MainActor func test_applyDiscount_validCode_sets10Percent() {
        let vm = makeVM()
        vm.applyDiscount(code: "TOSS10")
        XCTAssertEqual(vm.discountRate, 0.1)
    }

    @MainActor func test_applyDiscount_lowercaseCode_accepted() {
        let vm = makeVM()
        vm.applyDiscount(code: "toss10")
        XCTAssertEqual(vm.discountRate, 0.1)
    }

    @MainActor func test_applyDiscount_invalidCode_setsZero() {
        let vm = makeVM()
        vm.applyDiscount(code: "INVALID")
        XCTAssertEqual(vm.discountRate, 0.0)
    }

    @MainActor func test_applyDiscount_emptyCode_setsZero() {
        let vm = makeVM()
        vm.applyDiscount(code: "")
        XCTAssertEqual(vm.discountRate, 0.0)
    }

    @MainActor func test_applyDiscount_resetsOnInvalidAfterValid() {
        let vm = makeVM()
        vm.applyDiscount(code: "TOSS10")
        vm.applyDiscount(code: "WRONG")
        XCTAssertEqual(vm.discountRate, 0.0)
    }
}

// MARK: - Payment Tests

final class PaymentTests: XCTestCase {

    @MainActor func test_pay_emptyCart_doesNotChangeState() async {
        let vm = makeVM()
        await vm.pay()
        XCTAssertEqual(vm.transactionState, .idle)
    }

    @MainActor func test_pay_success_setsSuccessState() async {
        let vm = makeVM()
        vm.addProduct(americano)
        await vm.pay()
        XCTAssertEqual(vm.transactionState, .success)
    }

    @MainActor func test_pay_success_clearsCart() async {
        let vm = makeVM()
        vm.addProduct(americano)
        await vm.pay()
        XCTAssertTrue(vm.cartItems.isEmpty)
    }

    @MainActor func test_pay_success_populatesReceipt() async {
        let stub = SpySDKClient()
        stub.receiptToReturn = POSReceipt(
            items: [ReceiptItem(name: "아메리카노", qty: 1, price: 4500)],
            total: 4500, discount: 0, vat: 409,
            method: "card",
            timestamp: "2026-05-04T12:00:00Z"
        )
        let vm = POSViewModel(sdk: stub)
        vm.addProduct(americano)
        await vm.pay()
        XCTAssertNotNil(vm.lastReceipt)
        XCTAssertEqual(vm.lastReceipt?.total, 4500)
    }

    @MainActor func test_pay_failure_setsFailureState() async {
        let stub = SpySDKClient()
        stub.shouldThrow = true
        let vm = POSViewModel(sdk: stub)
        vm.addProduct(americano)
        await vm.pay()
        XCTAssertEqual(vm.transactionState, .failure)
    }

    @MainActor func test_pay_failure_doesNotClearCart() async {
        let stub = SpySDKClient()
        stub.shouldThrow = true
        let vm = POSViewModel(sdk: stub)
        vm.addProduct(americano)
        await vm.pay()
        XCTAssertFalse(vm.cartItems.isEmpty)
    }

    @MainActor func test_pay_recordsCorrectMethod() async {
        let stub = SpySDKClient()
        let vm = POSViewModel(sdk: stub)
        vm.selectedPaymentMethod = .qr
        vm.addProduct(americano)
        await vm.pay()
        XCTAssertEqual(stub.lastChargeMethod, .qr)
    }

    @MainActor func test_pay_recordsCorrectAmount() async {
        let stub = SpySDKClient()
        let vm = POSViewModel(sdk: stub)
        vm.addProduct(americano) // 4500
        vm.addProduct(muffin)   // 3800 → total 8300
        await vm.pay()
        XCTAssertEqual(stub.lastChargeAmount, 8300)
    }

    @MainActor func test_pay_withDiscount_chargesDiscountedAmount() async {
        let stub = SpySDKClient()
        let vm = POSViewModel(sdk: stub)
        vm.addProduct(americano) // 4500
        vm.applyDiscount(code: "TOSS10") // -450 → 4050
        await vm.pay()
        XCTAssertEqual(stub.lastChargeAmount, 4050)
    }
}

// MARK: - Helpers

private let americano = Product(name: "아메리카노", price: 4500, category: "음료")
private let muffin    = Product(name: "초코 머핀", price: 3800, category: "디저트")

@MainActor
private func makeVM() -> POSViewModel {
    POSViewModel(sdk: SpySDKClient())
}

// MARK: - Test Doubles

private final class SpySDKClient: SDKClientProtocol {
    var hasPendingTransaction: Bool = false
    var transactionState: TransactionState = .idle

    var shouldThrow = false
    var receiptToReturn: POSReceipt? = nil
    var lastChargeAmount: Int = 0
    var lastChargeMethod: PaymentMethod = .card

    func charge(amount: Int, method: PaymentMethod, items: [CartItem]) async throws {
        lastChargeAmount = amount
        lastChargeMethod = method
        if shouldThrow { throw ChargeError.failed }
    }

    func getReceipt() -> POSReceipt? { receiptToReturn }
    func getTodayTotal() -> Int { 0 }
}

private enum ChargeError: Error { case failed }
