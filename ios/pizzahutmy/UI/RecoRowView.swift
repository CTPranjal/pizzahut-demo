import SwiftUI

/// A horizontal recommendation row. Renders real catalog images, names and RM prices,
/// records PizzaHut Recommendation Viewed once per screen appearance and Clicked on tap.
struct RecoRowView: View {
    enum TapAction {
        /// Open the product sheet.
        case open
        /// One-tap add with default options (cart).
        case addToCart
        /// Close the current sheet first, then open the product (order confirmation).
        case closeThenOpen(() -> Void)
    }

    let slot: RecoSlot
    var context: Product?
    var tapAction: TapAction = .open
    /// Animate from the previously shown order to the new ranking (Home).
    var animateReorder = false

    @EnvironmentObject var engine: RecoEngine
    @EnvironmentObject var pe: ProductExperience
    @EnvironmentObject var cart: CartStore
    @EnvironmentObject var router: DeepLinkRouter

    @State private var shown: [RecoItem] = []
    @State private var viewedFired = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if pe.recoStrategy != .off && !shown.isEmpty {
                header
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 12) {
                        ForEach(Array(shown.enumerated()), id: \.element.id) { index, item in
                            RecoCard(item: item, showWhy: engine.showWhy, showsAdd: isAddRow) { tap(item, position: index + 1) }
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
        .onAppear { refresh(firstAppearance: true) }
        .onDisappear { viewedFired = false }
        .onChange(of: pe.recoStrategy) { _ in refresh() }
        .onChange(of: pe.recoPinnedIds) { _ in refresh() }
        .onChange(of: pe.recoRowTitle) { _ in refresh() }
        .onChange(of: cart.itemCount) { _ in refresh() }
        .onChange(of: context?.id) { _ in viewedFired = false; refresh(firstAppearance: true) }
    }

    private var isAddRow: Bool { if case .addToCart = tapAction { return true }; return false }

    private var header: some View {
        let title = engine.title(for: slot, strategy: pe.recoStrategy, homeTitle: pe.recoRowTitle)
        let words = title.split(separator: " ", maxSplits: 1).map(String.init)
        return SectionHeader(lead: words.first ?? title, accent: words.count > 1 ? words[1] : "")
    }

    private func compute() -> [RecoItem] {
        engine.items(for: slot, strategy: pe.recoStrategy, pinnedIds: pe.recoPinnedIds, context: context, cart: cart.items)
    }

    private func refresh(firstAppearance: Bool = false) {
        let fresh = compute()
        if firstAppearance && animateReorder, let previous = engine.lastShown[slot], !previous.isEmpty, previous != fresh {
            shown = previous
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) { shown = fresh }
            }
        } else {
            shown = fresh
        }
        engine.lastShown[slot] = fresh
        if firstAppearance { fireViewed(fresh) }
    }

    private func fireViewed(_ items: [RecoItem]) {
        guard !viewedFired, !items.isEmpty, pe.recoStrategy != .off else { return }
        viewedFired = true
        Analytics.track(.recommendationViewed, [
            "Slot": slot.rawValue,
            "Strategy": pe.recoStrategy.rawValue,
            "Product IDs": items.map(\.product.id).joined(separator: ","),
            "Count": items.count,
        ])
    }

    private func tap(_ item: RecoItem, position: Int) {
        Analytics.track(.recommendationClicked, [
            "Slot": slot.rawValue,
            "Strategy": pe.recoStrategy.rawValue,
            "Product ID": item.product.id,
            "Position": position,
            "Reason": item.analyticsReason,
        ])
        switch tapAction {
        case .open:
            router.openProduct(item.product, fromRecommendation: slot)
        case .addToCart:
            addWithDefaults(item.product)
        case let .closeThenOpen(close):
            close()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { router.openProduct(item.product, fromRecommendation: slot) }
        }
    }

    /// One-tap add: pizzas get the preferred size (Regular by default) and the first crust.
    private func addWithDefaults(_ p: Product) {
        var line = CartItem(product: p, quantity: 1)
        if let tier = p.pizzaTier, let sizes = Catalog.shared.pizzaOptions.tiers[tier]?.sizes {
            let size = sizes.first { $0.id == engine.preferredSizeId } ?? sizes.first { $0.id == "REG" } ?? sizes.first
            line.size = size
            line.crust = size.flatMap { Catalog.shared.pizzaOptions.crusts[$0.id]?.first }
        }
        line.source = "Recommendation"
        line.recoSlot = slot
        cart.add(line)
        engine.record(.addedToCart, p, size: line.size?.name)
        Analytics.track(.addedToCart, [
            "Product ID": p.id, "Product Name": p.name, "Category": p.categoryName,
            "Price": line.unitPrice, "Quantity": 1, "Cart Value": cart.subtotal,
            "Source": "Recommendation", "Slot": slot.rawValue,
        ])
    }
}

struct RecoCard: View {
    let item: RecoItem
    let showWhy: Bool
    var showsAdd = false
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 5) {
                CatalogImageView(path: item.product.image, mode: .fit)
                    .frame(width: 140, height: 104)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                Text(item.product.name).font(Theme.body(13, .bold)).foregroundColor(Theme.ink)
                    .lineLimit(2).multilineTextAlignment(.leading).frame(height: 34, alignment: .topLeading)
                HStack {
                    Text(item.product.price.rm).font(Theme.body(13, .bold)).foregroundColor(Theme.red)
                    Spacer(minLength: 2)
                    if showsAdd {
                        Text("+ Add").font(Theme.body(12, .semibold)).foregroundColor(Theme.red)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.red, lineWidth: 1))
                    }
                }
                if !item.reason.isEmpty {
                    Text(item.reason).font(Theme.body(11, .medium)).foregroundColor(Theme.grey)
                        .lineLimit(2).multilineTextAlignment(.leading)
                }
                if showWhy {
                    Text(String(format: "Why this? score %.2f · %@", item.score, item.kind.rawValue)
                         + (item.reason.isEmpty ? "" : " · " + item.reason))
                        .font(.system(size: 9, design: .monospaced)).foregroundColor(Theme.greyLight)
                        .lineLimit(3).multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
            }
            .padding(8)
            .frame(width: 156)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("reco-\(item.product.id)")
    }
}
