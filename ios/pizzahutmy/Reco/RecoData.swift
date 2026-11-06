import Foundation

/// Curated data bundled from recs/pairings.json and recs/popular.json (see docs/RECS.md).
/// Unknown product IDs are dropped at load time, so only real catalog products can surface.
struct RecoData {
    private struct PairingsFile: Decodable {
        let pizzaSubcategories: [String: [String]]
        let categories: [String: [String]]
    }
    private struct PopularFile: Decodable {
        let label: String
        let productIds: [String]
    }

    let pizzaPairings: [String: [Product]]
    let categoryPairings: [String: [Product]]
    let popular: [Product]
    let popularLabel: String

    static let shared = RecoData()

    private init() {
        let catalog = Catalog.shared
        func load<T: Decodable>(_ name: String, as: T.Type) -> T? {
            guard let url = Bundle.main.url(forResource: name, withExtension: "json"),
                  let data = try? Data(contentsOf: url) else { return nil }
            return try? JSONDecoder().decode(T.self, from: data)
        }
        func products(_ ids: [String]) -> [Product] { ids.compactMap { catalog.product($0) } }

        let pairings = load("pairings", as: PairingsFile.self)
        pizzaPairings = (pairings?.pizzaSubcategories ?? [:]).mapValues(products)
        categoryPairings = (pairings?.categories ?? [:]).mapValues(products)
        let pop = load("popular", as: PopularFile.self)
        popular = products(pop?.productIds ?? [])
        popularLabel = pop?.label ?? "Popular right now"
    }

    /// Products that pair well with the given product: by subcategory for pizzas, by category otherwise.
    func pairings(for product: Product) -> [Product] {
        let list = product.isPizza ? pizzaPairings[product.subcategory] : categoryPairings[product.category]
        return (list ?? []).filter { $0.id != product.id }
    }
}
