# POS Core Demo

iPad/iPhone POS app built with SwiftUI, demonstrating a multi-module iOS architecture with a Go-powered business logic SDK.

This project was built as a hands-on exploration of the Toss POS iOS stack — Tuist, Micro Feature Architecture, gomobile, Swift Concurrency, Combine, and WKWebView.

---

## Features

- **Product grid** — category tabs, real-time search with Combine debounce
- **Cart** — add/remove items, quantity stepper, discount code (TOSS10), VAT calculation
- **Payment methods** — card, QR (CoreImage QR code generation), cash
- **QR payment flow** — sheet with generated QR code; confirm triggers Go SDK charge
- **Receipt** — rendered as HTML in WKWebView with a JS → Swift dismiss bridge
- **Today's total** — live polling via Go SDK session state
- **Adaptive layout** — iPad: 2-column split view / iPhone: NavigationStack

---

## Architecture

### Module Graph

```
App (POSCoreDemo)
├── POSImplementation
│   ├── Feature/Products   ProductGridView, ProductCard, SearchViewModel
│   ├── Feature/Cart       CartPanelView, CartItemRow
│   ├── Feature/Payment    QRPaymentSheet
│   ├── Feature/Receipt    ReceiptView (WKWebView), HTMLReceiptBuilder
│   └── Core               POSViewModel, POSSplitView
├── DesignSystem           TDS tokens — colors, spacing, radius, card style
├── POSInterface           Product, SDKViewModelProtocol (protocols only)
├── Domain                 SDKClientProtocol, CartItem, POSReceipt, PaymentMethod
└── CoreSDK                SDKClient wrapping POSCore.xcframework (Go)
```

Dependency direction: `App → [POSImplementation, CoreSDK]` — `CoreSDK` is the only module that imports the Go xcframework. All other modules depend on `Domain` abstractions only.

### Go SDK Bridge

Business logic (pricing, receipt generation, session state) lives in a Go package compiled to an iOS xcframework via `gomobile bind`.

```
sdk/pos.go  →  gomobile bind  →  Frameworks/POSCore.xcframework
                                         ↓
                             CoreSDK/Sources/GoSDKBridge.swift
                             CoreSDK/Sources/MockSDKClient.swift
```

Go functions use the ObjC out-param pattern that gomobile generates — not auto-bridged to Swift `throws`:

```swift
// gomobile generates: func PosCharge(_ amount: Int64, _ method: String, _ itemsJSON: String, _ ret0_: UnsafeMutablePointer<ObjCBool>!, _ error: AutoreleasingUnsafeMutablePointer<NSError?>!)
PosCharge(chargeAmount, chargeMethod, itemsJSON, &retVal, &nsErr)
```

Sync Go calls are dispatched via `Task.detached(priority: .userInitiated)` to avoid blocking the main actor.

### Key Technical Choices

| Concern | Approach |
|---|---|
| Search filtering | `Publishers.CombineLatest` + `.debounce(300ms)` in `SearchViewModel` |
| Receipt rendering | `WKWebView` + `WKScriptMessageHandler` — JS `posClose` message → Swift `dismiss()` |
| Go bridge | `Task.detached` wrapping sync xcframework calls |
| Module isolation | `DesignSystem` has no Domain import; `CoreSDK` is the sole xcframework importer |
| Adaptive layout | `horizontalSizeClass == .regular` → iPad split, `.compact` → iPhone stack |

---

## Project Setup

### Requirements

- Xcode 16+
- [mise](https://mise.jdx.dev) (manages Tuist version)
- Ruby + Bundler (for Fastlane)

### Getting Started

```bash
# 1. Install Tuist via mise
mise install

# 2. Generate the Xcode project
cd POSCoreDemo
tuist generate

# 3. Open and run
open POSCoreDemo.xcworkspace
```

> The xcworkspace is git-ignored. Always run `tuist generate` after cloning or after modifying `Project.swift`.

---

## Running Tests

```bash
cd POSCoreDemo

# With Fastlane (recommended)
bundle install
bundle exec fastlane test

# Or directly
xcodebuild test \
  -workspace POSCoreDemo.xcworkspace \
  -scheme POSImplementationTests \
  -destination 'platform=iOS Simulator,name=iPad Air 13-inch (M4)'
```

**Test coverage** — `POSImplementationTests` (29 tests):

| Suite | Count | What it covers |
|---|---|---|
| `CartTests` | 8 | add, duplicate accumulation, quantity delta, zero/below-zero removal |
| `DiscountTests` | 5 | valid code, case-insensitive, invalid/empty, reset after invalid |
| `PriceCalculationTests` | 7 | subtotal, discount amount, VAT (post-discount), total |
| `PaymentTests` | 9 | empty cart guard, success/failure state, cart cleared, receipt populated, charge amount/method verified via `SpySDKClient` |

---

## Fastlane Lanes

```bash
bundle exec fastlane generate   # tuist generate
bundle exec fastlane build      # compile for simulator
bundle exec fastlane test       # run XCTest suite → fastlane/test_output/test-results.xml
bundle exec fastlane archive    # ad-hoc IPA → fastlane/build/POSCoreDemo.ipa
```

---

## Repository Structure

```
pos-core-demo/
├── Frameworks/
│   └── POSCore.xcframework     # Pre-compiled Go SDK
├── sdk/
│   ├── pos.go                  # Go business logic (charge, receipt, session)
│   └── go.mod
└── POSCoreDemo/
    ├── Project.swift           # Tuist manifest — all targets and dependencies
    ├── App/                    # App entry point
    ├── DesignSystem/           # TDS design tokens (separate framework)
    ├── Domain/                 # SDKClientProtocol, DTOs
    ├── POSInterface/           # Product, view model protocols
    ├── CoreSDK/                # Go xcframework wrapper
    ├── POSImplementation/
    │   ├── Sources/
    │   │   ├── Core/           # POSViewModel, POSSplitView
    │   │   └── Feature/
    │   │       ├── Products/
    │   │       ├── Cart/
    │   │       ├── Payment/
    │   │       └── Receipt/
    │   └── Tests/              # XCTest suite
    └── fastlane/
        └── Fastfile
```

---

## Tech Stack

- **Swift** / SwiftUI, Swift Concurrency, Combine
- **WebKit** — WKWebView, WKScriptMessageHandler
- **Go** — business logic SDK compiled via gomobile
- **Tuist 4** — project generation and multi-module management
- **Fastlane** — build, test, archive automation
- **XCTest** — unit tests with protocol-based test doubles
