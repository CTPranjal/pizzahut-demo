import SwiftUI

struct MenuView: View {
    @EnvironmentObject var router: DeepLinkRouter
    @EnvironmentObject var cart: CartStore
    @EnvironmentObject var session: SessionStore
    @EnvironmentObject var pe: ProductExperience
    @State private var selected: String = ""
    @State private var query = ""
    @State private var lastTrackedCategory = ""

    private var categories: [Catalog.Category] { pe.orderedCategories }

    private var searchResults: [Product] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return [] }
        return Catalog.shared.products.filter {
            $0.name.lowercased().contains(q) || $0.description.lowercased().contains(q) || $0.subcategory.lowercased().contains(q)
        }
    }

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    searchBar
                    if query.isEmpty { categoryChips }
                    ScrollView {
                        VStack(spacing: 14) {
                            if query.isEmpty {
                                DisplaySlotView(slot: .menuTop, height: 120) { menuTopFallback }
                                    .padding(.top, 12)
                                productList(Catalog.shared.products(in: selected), grouped: true)
                            } else {
                                Text("\(searchResults.count) result\(searchResults.count == 1 ? "" : "s") for \"\(query)\"")
                                    .font(Theme.body(13)).foregroundColor(Theme.grey)
                                    .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 16).padding(.top, 12)
                                productList(searchResults, grouped: false)
                            }
                        }
                        .padding(.bottom, cart.itemCount > 0 ? 80 : 20)
                    }
                }
                CartPill()
            }
            .background(Theme.surface.ignoresSafeArea())
            .navigationTitle("Menu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { router.showCart = true } label: {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "cart").foregroundColor(Theme.ink)
                            Badge(count: cart.itemCount).offset(x: 8, y: -6)
                        }
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
        .onAppear {
            let start = router.menuCategoryId ?? (selected.isEmpty ? categories.first?.id ?? "" : selected)
            router.menuCategoryId = nil
            select(start)
        }
        .onChange(of: router.menuCategoryId) { id in
            if let id { select(id); router.menuCategoryId = nil }
        }
    }

    private func select(_ id: String) {
        guard Catalog.shared.category(id) != nil else { return }
        selected = id
        guard lastTrackedCategory != id, let c = Catalog.shared.category(id) else { return }
        lastTrackedCategory = id
        Analytics.track(.categoryViewed, ["Category": c.name])
        session.noteCategoryView(id)
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundColor(Theme.greyLight)
            TextField("Search pizzas, pasta, sides", text: $query)
                .submitLabel(.search)
                .onSubmit {
                    let q = query.trimmingCharacters(in: .whitespaces)
                    guard !q.isEmpty else { return }
                    Analytics.track(.searchPerformed, ["Query": q, "Results Count": searchResults.count])
                }
            if !query.isEmpty {
                Button { query = "" } label: { Image(systemName: "xmark.circle.fill").foregroundColor(Theme.greyLight) }
            }
        }
        .padding(.horizontal, 12).frame(height: 42)
        .background(Color.white).clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border))
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(Color.white)
    }

    private var categoryChips: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(categories) { c in
                        Button { select(c.id) } label: {
                            Text(c.name)
                                .font(Theme.body(14, selected == c.id ? .bold : .medium))
                                .foregroundColor(selected == c.id ? Theme.red : Theme.text)
                                .padding(.horizontal, 14).padding(.vertical, 8)
                                .background(selected == c.id ? Theme.redTint.opacity(0.5) : Color.white)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(selected == c.id ? Theme.red : Theme.border))
                        }
                        .id(c.id)
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 10)
            }
            .background(Color.white)
            .onChange(of: selected) { id in withAnimation { proxy.scrollTo(id, anchor: .center) } }
        }
    }

    /// Fallback for menu_top: the real category tile and its name.
    @ViewBuilder private var menuTopFallback: some View {
        if let c = Catalog.shared.category(selected) {
            HStack(spacing: 14) {
                CatalogImageView(path: c.image, mode: .fill).frame(width: 96, height: 90).clipShape(RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 4) {
                    Text(c.name).font(Theme.heading(22)).foregroundColor(Theme.ink)
                    Text("\(Catalog.shared.products(in: c.id).count) items · \(cart.orderMode.rawValue)").font(Theme.body(13)).foregroundColor(Theme.grey)
                }
                Spacer()
            }
            .padding(10).background(Color.white).clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, 16)
        }
    }

    @ViewBuilder private func productList(_ products: [Product], grouped: Bool) -> some View {
        if grouped {
            let groups = Dictionary(grouping: products, by: \.subcategory)
            let order = products.map(\.subcategory).reduce(into: [String]()) { if !$0.contains($1) { $0.append($1) } }
            ForEach(order, id: \.self) { sub in
                VStack(alignment: .leading, spacing: 10) {
                    if !sub.isEmpty && order.count > 1 {
                        Text(sub).font(Theme.body(15, .bold)).foregroundColor(Theme.ink).padding(.horizontal, 16)
                    }
                    ForEach(groups[sub] ?? []) { ProductRow(product: $0) }
                }
            }
        } else {
            ForEach(products) { ProductRow(product: $0) }
        }
    }
}

/// Product card in the site's combo-card style: image, name, description, price, outlined Add button.
struct ProductRow: View {
    let product: Product
    @EnvironmentObject var router: DeepLinkRouter

    var body: some View {
        Button { router.product = product } label: {
            HStack(alignment: .top, spacing: 12) {
                CatalogImageView(path: product.image, mode: .fit)
                    .frame(width: 104, height: 104)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 6) {
                        Text(product.name).font(Theme.body(15, .bold)).foregroundColor(Theme.ink).multilineTextAlignment(.leading)
                        if product.appOnly {
                            Text("APP ONLY").font(.system(size: 9, weight: .heavy)).foregroundColor(.white)
                                .padding(.horizontal, 5).padding(.vertical, 2).background(Theme.red).clipShape(Capsule())
                        }
                    }
                    if !product.description.isEmpty {
                        Text(product.description).font(Theme.body(12)).foregroundColor(Theme.grey).lineLimit(2).multilineTextAlignment(.leading)
                    }
                    Spacer(minLength: 2)
                    HStack {
                        (Text(product.isPizza ? "From " : "").foregroundColor(Theme.grey) + Text(product.price.rm).foregroundColor(Theme.red))
                            .font(Theme.body(14, .bold))
                        Spacer()
                        Text("Add").font(Theme.body(13, .semibold)).foregroundColor(Theme.red)
                            .padding(.horizontal, 18).padding(.vertical, 6)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.red, lineWidth: 1.2))
                    }
                }
            }
            .padding(10)
            .background(Color.white).clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.border))
            .padding(.horizontal, 16)
        }
        .buttonStyle(.plain)
    }
}
