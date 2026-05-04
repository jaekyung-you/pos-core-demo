import SwiftUI
import DesignSystem
import Domain
import POSInterface

struct ProductCard: View {
    let product: Product
    @ObservedObject var viewModel: POSViewModel

    private var qtyInCart: Int {
        viewModel.cartItems.first(where: { $0.name == product.name })?.qty ?? 0
    }

    var body: some View {
        Button {
            viewModel.addProduct(product)
        } label: {
            VStack(alignment: .leading, spacing: TDS.Spacing.sm) {
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: TDS.Radius.badge)
                        .fill(TDS.Color.gray100)
                        .frame(height: 80)
                        .overlay(
                            Image(systemName: categoryIcon(product.category))
                                .font(.system(size: 28))
                                .foregroundColor(TDS.Color.gray400)
                        )

                    if qtyInCart > 0 {
                        Text("\(qtyInCart)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 22, height: 22)
                            .background(TDS.Color.blue500)
                            .clipShape(Circle())
                            .offset(x: 6, y: -6)
                    }
                }

                Text(product.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(TDS.Color.gray900)
                    .lineLimit(1)

                Text("₩\(product.price.formatted())")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(TDS.Color.blue500)
            }
            .padding(TDS.Spacing.lg)
            .tdsCardStyle()
        }
        .buttonStyle(.plain)
    }

    private func categoryIcon(_ category: String) -> String {
        switch category {
        case "음료":   return "cup.and.saucer.fill"
        case "디저트": return "birthday.cake.fill"
        default:      return "bag.fill"
        }
    }
}
