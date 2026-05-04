import SwiftUI
import DesignSystem
import Domain

struct CartItemRow: View {
    let item: CartItem
    let onQuantityChange: (Int) -> Void

    var body: some View {
        HStack(spacing: TDS.Spacing.md) {
            Text(item.name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(TDS.Color.gray900)
                .frame(maxWidth: .infinity, alignment: .leading)

            quantityControl

            Text("₩\((item.price * item.qty).formatted())")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(TDS.Color.gray900)
                .frame(minWidth: 70, alignment: .trailing)
        }
        .padding(.horizontal, TDS.Spacing.lg)
        .padding(.vertical, TDS.Spacing.md)
        .background(TDS.Color.gray50)
        .clipShape(RoundedRectangle(cornerRadius: TDS.Radius.badge + 4))
    }

    private var quantityControl: some View {
        HStack(spacing: TDS.Spacing.md) {
            Button { onQuantityChange(-1) } label: {
                Image(systemName: "minus")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(TDS.Color.blue500)
                    .frame(width: 20, height: 20)
            }

            Text("\(item.qty)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(TDS.Color.gray900)
                .frame(minWidth: 20, alignment: .center)

            Button { onQuantityChange(+1) } label: {
                Image(systemName: "plus")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(TDS.Color.blue500)
                    .frame(width: 20, height: 20)
            }
        }
        .padding(.horizontal, TDS.Spacing.sm)
        .padding(.vertical, TDS.Spacing.xs + 2)
        .background(TDS.Color.white)
        .clipShape(RoundedRectangle(cornerRadius: TDS.Radius.badge))
        .overlay(
            RoundedRectangle(cornerRadius: TDS.Radius.badge)
                .stroke(TDS.Color.gray200, lineWidth: 1)
        )
    }
}
