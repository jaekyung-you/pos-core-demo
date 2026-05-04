import SwiftUI
import DesignSystem
import Combine
import Domain
import POSInterface

struct ProductGridView: View {
    @ObservedObject var viewModel: POSViewModel
    @StateObject private var search = SearchViewModel()

    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var categories: [String] {
        ["전체"] + Array(Set(SampleProducts.all.map(\.category))).sorted()
    }

    var body: some View {
        VStack(spacing: 0) {
            searchBar
            categoryTabs
            productGrid
        }
    }

    // MARK: - Search

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(TDS.Color.gray400)
            TextField("상품 검색", text: $search.searchText)
                .font(.system(size: 15))
        }
        .padding(.horizontal, TDS.Spacing.lg)
        .padding(.vertical, TDS.Spacing.md)
        .background(TDS.Color.gray100)
        .clipShape(RoundedRectangle(cornerRadius: TDS.Radius.input))
        .padding(.horizontal, TDS.Spacing.lg)
        .padding(.vertical, TDS.Spacing.md)
        .background(TDS.Color.white)
    }

    // MARK: - Category Tabs

    private var categoryTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(categories, id: \.self) { cat in
                    Button {
                        search.selectedCategory = cat
                    } label: {
                        VStack(spacing: 0) {
                            Text(cat)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(search.selectedCategory == cat ? TDS.Color.blue500 : TDS.Color.gray400)
                                .padding(.horizontal, TDS.Spacing.lg)
                                .padding(.vertical, TDS.Spacing.md)
                            Rectangle()
                                .fill(search.selectedCategory == cat ? TDS.Color.blue500 : .clear)
                                .frame(height: 2)
                        }
                    }
                }
            }
        }
        .background(TDS.Color.white)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }

    // MARK: - Product Grid

    private var productGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: TDS.Spacing.md) {
                ForEach(search.filteredProducts) { product in
                    ProductCard(product: product, viewModel: viewModel)
                }
            }
            .padding(TDS.Spacing.lg)
        }
        .background(TDS.Color.gray100)
    }
}

// MARK: - Sample Data

enum SampleProducts {
    static let all: [Product] = [
        Product(name: "아메리카노",   price: 4500, category: "음료"),
        Product(name: "카페 라떼",   price: 5000, category: "음료"),
        Product(name: "카푸치노",    price: 5500, category: "음료"),
        Product(name: "말차 라떼",   price: 5500, category: "음료"),
        Product(name: "오렌지 주스", price: 4000, category: "음료"),
        Product(name: "딸기 스무디", price: 6000, category: "음료"),
        Product(name: "초코 머핀",   price: 3800, category: "디저트"),
        Product(name: "크로아상",    price: 4200, category: "디저트"),
        Product(name: "에그 타르트", price: 3500, category: "디저트"),
    ]
}
