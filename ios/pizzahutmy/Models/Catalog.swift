import Foundation

struct Catalog: Decodable {
    struct Brand: Decodable { let logo: String; let favicon: String; let appIcon: String; let squareInvert: String; let feedGoodTimes: String; let redBackground: String; let placeholder: String }
    struct Banner: Decodable, Identifiable { let id: String; let web: String; let app: String; let productId: String? }
    struct Category: Decodable, Identifiable, Hashable { let id: String; let name: String; let image: String }
    struct Deal: Decodable, Identifiable { let id: String; let name: String; let price: Double; let image: String }
    struct Store: Decodable, Identifiable, Hashable { let id: String; let name: String; let area: String; let address: String; let lat: Double; let lng: Double }

    struct PizzaOptions: Decodable {
        struct Tier: Decodable { let sizes: [Option] }
        struct Option: Decodable, Hashable, Identifiable { let id: String; let name: String; let add: Double }
        let tiers: [String: Tier]
        let crusts: [String: [Option]]
        let toppings: [String: [Option]]
        let maxToppings: Int
    }

    let brand: Brand
    let icons: [String: String]
    let banners: [Banner]
    let categories: [Category]
    let products: [Product]
    let deals: [Deal]
    let pizzaOptions: PizzaOptions
    let stores: [Store]

    static let shared: Catalog = {
        guard let url = Bundle.main.url(forResource: "catalog", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let catalog = try? JSONDecoder().decode(Catalog.self, from: data) else {
            fatalError("catalog.json missing or invalid. Run scripts/build_assets.py")
        }
        return catalog
    }()

    func product(_ id: String) -> Product? { products.first { $0.id == id } }
    func category(_ id: String) -> Category? { categories.first { $0.id == id } }
    func products(in categoryId: String) -> [Product] { products.filter { $0.category == categoryId } }
    func store(_ id: String) -> Store? { stores.first { $0.id == id } }
}

struct Product: Decodable, Identifiable, Hashable {
    let id: String
    let name: String
    let description: String
    let price: Double
    let category: String
    let subcategory: String
    let image: String?
    let appOnly: Bool
    let pizzaTier: String?
    /// Original public CDN URL of the product image (sent as the Image URL event property).
    let imageUrl: String

    var isPizza: Bool { pizzaTier != nil }
    var categoryName: String { Catalog.shared.category(category)?.name ?? category }
}

/// Maps a catalog image path to its asset catalog name (same rule as scripts/build_assets.py).
enum CatalogImage {
    static func assetName(for path: String?) -> String {
        guard var p = path, !p.isEmpty else { return assetName(for: Catalog.shared.brand.placeholder) }
        if p.hasPrefix("img/") { p.removeFirst(4) }
        p = (p as NSString).deletingPathExtension
        return p.replacingOccurrences(of: "/", with: "-")
    }
}
