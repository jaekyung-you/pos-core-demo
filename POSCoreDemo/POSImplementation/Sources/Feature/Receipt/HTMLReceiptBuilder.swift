import Foundation
import Domain

enum HTMLReceiptBuilder {
    static func build(from receipt: POSReceipt) -> String {
        let rows = receipt.items.map { item in
            """
            <tr>
              <td>\(item.name)</td>
              <td class="center">× \(item.qty)</td>
              <td class="right">₩\(formatAmount(item.price * item.qty))</td>
            </tr>
            """
        }.joined()

        let methodLabel: String
        let methodIcon: String
        switch receipt.method {
        case "card": methodLabel = "카드 결제"; methodIcon = "💳"
        case "qr":   methodLabel = "QR 결제";  methodIcon = "📱"
        default:     methodLabel = "현금 결제"; methodIcon = "💵"
        }

        let dateStr = String(receipt.timestamp.prefix(10))
        let discountRow = receipt.discount > 0
            ? "<tr><td colspan='2' class='label red'>할인</td><td class='right red'>−₩\(formatAmount(receipt.discount))</td></tr>"
            : ""

        return """
        <!DOCTYPE html>
        <html lang="ko">
        <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
        <style>
          * { box-sizing: border-box; margin: 0; padding: 0; }
          body {
            font-family: -apple-system, 'Helvetica Neue', sans-serif;
            background: #F2F3F5;
            min-height: 100vh;
            display: flex;
            flex-direction: column;
            align-items: center;
            padding: 32px 20px;
          }
          .success-icon {
            font-size: 56px;
            margin-bottom: 12px;
          }
          .success-title {
            font-size: 20px;
            font-weight: 800;
            color: #191F28;
            margin-bottom: 32px;
          }
          .card {
            background: #fff;
            border-radius: 16px;
            padding: 24px;
            width: 100%;
            max-width: 440px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.06);
          }
          .card-title {
            font-size: 15px;
            font-weight: 700;
            color: #191F28;
            margin-bottom: 16px;
          }
          hr {
            border: none;
            border-top: 1px solid #E5E8EB;
            margin: 14px 0;
          }
          table {
            width: 100%;
            border-collapse: collapse;
          }
          td {
            font-size: 14px;
            color: #495057;
            padding: 5px 0;
          }
          td.center { text-align: center; color: #8B95A1; font-size: 13px; }
          td.right   { text-align: right; }
          td.label   { color: #8B95A1; }
          td.red     { color: #F04452; }
          .total-row td {
            font-size: 16px;
            font-weight: 800;
            color: #191F28;
            padding: 4px 0;
          }
          .meta {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-top: 14px;
            font-size: 13px;
            color: #8B95A1;
          }
          .close-btn {
            margin-top: 32px;
            width: 100%;
            max-width: 440px;
            padding: 18px;
            font-size: 17px;
            font-weight: 700;
            color: #fff;
            background: #3182F6;
            border: none;
            border-radius: 14px;
            cursor: pointer;
            -webkit-tap-highlight-color: transparent;
          }
          .close-btn:active { opacity: 0.85; }
        </style>
        </head>
        <body>
          <div class="success-icon">✅</div>
          <div class="success-title">결제가 완료되었습니다</div>

          <div class="card">
            <div class="card-title">영수증</div>
            <hr>
            <table>
              \(rows)
            </table>
            <hr>
            <table>
              \(discountRow)
              <tr><td class="label">부가세 (VAT)</td><td></td><td class="right">₩\(formatAmount(receipt.vat))</td></tr>
            </table>
            <hr>
            <table>
              <tr class="total-row">
                <td>합계</td>
                <td></td>
                <td class="right">₩\(formatAmount(receipt.total))</td>
              </tr>
            </table>
            <div class="meta">
              <span>\(methodIcon) \(methodLabel)</span>
              <span>\(dateStr)</span>
            </div>
          </div>

          <button class="close-btn" onclick="webkit.messageHandlers.posClose.postMessage('close')">
            확인
          </button>
        </body>
        </html>
        """
    }

    private static func formatAmount(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}
