import Foundation
import Combine
import POSInterface

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var selectedCategory: String = "전체"
    @Published private(set) var filteredProducts: [Product] = SampleProducts.all

    private var cancellables = Set<AnyCancellable>()

    init() {
        // Combine: debounce search input + react to category changes
        Publishers.CombineLatest($searchText, $selectedCategory)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .map { text, category -> [Product] in
                let base = category == "전체"
                    ? SampleProducts.all
                    : SampleProducts.all.filter { $0.category == category }
                guard !text.isEmpty else { return base }
                return base.filter { $0.name.localizedCaseInsensitiveContains(text) }
            }
            .assign(to: &$filteredProducts)
    }
}
