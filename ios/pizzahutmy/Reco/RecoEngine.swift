import Foundation
import UIKit

/// Where a recommendation row is shown. The raw value is sent as the Slot event property.
enum RecoSlot: String {
    case home = "home_picked_for_you"
    case productDetail = "product_goes_great_with"
    case cart = "cart_complete_your_meal"
    case confirmation = "order_next_time_try"
}

enum RecoStrategy: String {
    case personalised, popular, off

    init(variable: String) {
        self = RecoStrategy(rawValue: variable.trimmingCharacters(in: .whitespaces).lowercased()) ?? .personalised
    }
}

struct RecoItem: Identifiable, Equatable {
    enum Kind: String { case viewed, subcategory, category, pairing, popular, pinned }
    let product: Product
    /// Shown under the card. Built only from the user's own activity; empty for pinned and popular items.
    let reason: String
    let kind: Kind
    let score: Double
    var id: String { product.id }

    /// Value of the Reason event property.
    var analyticsReason: String {
        switch kind {
        case .pinned: return "Pinned"
        case .popular: return "Popular"
        default: return reason
        }
    }
}

/// On-device recommendation engine. Keeps affinity scores per product, subcategory and category,
/// persisted in UserDefaults and cleared on logout. Nothing leaves the device except the
/// PizzaHut Top Affinity profile property and the recommendation events.
final class RecoEngine: ObservableObject {
    static let shared = RecoEngine()

    enum Signal: Double {
        case viewed = 1, customised = 2, addedToCart = 3, orderedUnit = 5
    }

    private struct State: Codable {
        var product: [String: Double] = [:]
        var subcategory: [String: Double] = [:]
        var category: [String: Double] = [:]
        /// Most recent first.
        var recentViews: [String] = []
        var sizeCounts: [String: Int] = [:]
        var lastTopAffinity: String?
        var lastSessionAt: Date?
    }

    static let decayPerSession = 0.10
    private static let stateKey = "recoState"
    private static let debugKey = "recoDebug"
    private static let sessionGap: TimeInterval = 30 * 60
    private static let maxRecent = 10
    private static let rowLimit = 10

    @Published private var state = State()
    /// "Why this?" rehearsal toggle: shows score and reason under each card.
    @Published var showWhy: Bool { didSet { UserDefaults.standard.set(showWhy, forKey: Self.debugKey) } }
    /// Items ordered in the current session are excluded from rows.
    @Published private(set) var orderedThisSession = Set<String>()
    /// Last list shown per slot, so a row can animate from its previous order.
    var lastShown: [RecoSlot: [RecoItem]] = [:]

    private var suppressAffinityPush = false
    private let data = RecoData.shared
    private let catalog = Catalog.shared

    private init() {
        showWhy = UserDefaults.standard.bool(forKey: Self.debugKey)
        if let raw = UserDefaults.standard.data(forKey: Self.stateKey),
           let saved = try? JSONDecoder().decode(State.self, from: raw) {
            state = saved
        }
        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] _ in
            self?.startSessionIfNeeded()
        }
    }

    var hasScores: Bool { !state.product.isEmpty }

    // MARK: Sessions

    /// Each new session decays all scores by 10%. Called at launch and when returning after 30+ minutes.
    func startSessionIfNeeded(now: Date = Date()) {
        if let last = state.lastSessionAt, now.timeIntervalSince(last) < Self.sessionGap {
            state.lastSessionAt = now
            save()
            return
        }
        let keep = 1 - Self.decayPerSession
        state.product = state.product.mapValues { $0 * keep }
        state.subcategory = state.subcategory.mapValues { $0 * keep }
        state.category = state.category.mapValues { $0 * keep }
        state.lastSessionAt = now
        orderedThisSession = []
        save()
    }

    // MARK: Signals

    func record(_ signal: Signal, _ product: Product, units: Int = 1, size: String? = nil) {
        let w = signal.rawValue * Double(max(units, 1))
        state.product[product.id, default: 0] += w
        if !product.subcategory.isEmpty { state.subcategory[subcategoryKey(product), default: 0] += w }
        state.category[product.category, default: 0] += w
        if signal == .viewed {
            state.recentViews.removeAll { $0 == product.id }
            state.recentViews.insert(product.id, at: 0)
            state.recentViews = Array(state.recentViews.prefix(Self.maxRecent))
        }
        if let size { state.sizeCounts[size, default: 0] += 1 }
        if signal == .orderedUnit { orderedThisSession.insert(product.id) }
        save()
        pushTopAffinityIfChanged()
    }

    /// Clears all scores (logout and the "Reset recommendations" rehearsal tool).
    func reset() {
        state = State(lastSessionAt: Date())
        orderedThisSession = []
        lastShown = [:]
        save()
    }

    /// Preferred size for one-tap adds, learned from customisations. Regular by default.
    var preferredSizeId: String {
        let byName = state.sizeCounts.max { $0.value < $1.value }?.key
        return Catalog.shared.pizzaOptions.tiers.values.flatMap(\.sizes).first { $0.name == byName }?.id ?? "REG"
    }

    // MARK: Explanations for the "Why this?" tool

    func score(of product: Product) -> Double { state.product[product.id] ?? 0 }

    // MARK: Rows

    func items(for slot: RecoSlot, strategy: RecoStrategy, pinnedIds: String,
               context: Product? = nil, cart: [CartItem] = []) -> [RecoItem] {
        guard strategy != .off else { return [] }
        let excluded = Set(cart.map(\.product.id)).union(orderedThisSession)
        var base: [RecoItem]
        if strategy == .popular {
            base = popularItems(excluding: excluded)
        } else {
            switch slot {
            case .home, .confirmation:
                base = hasScores ? personalised(excluding: excluded) : popularItems(excluding: excluded)
            case .productDetail:
                base = context.map { pairingItems(for: $0, excluding: excluded.union([$0.id])) } ?? []
            case .cart:
                base = completeYourMeal(cart: cart, excluding: excluded)
            }
        }
        return Array(withPinned(pinnedIds, base).prefix(Self.rowLimit))
    }

    /// Row title for the slot, given the strategy and whether the user has any scores yet.
    func title(for slot: RecoSlot, strategy: RecoStrategy, homeTitle: String) -> String {
        if strategy == .popular { return data.popularLabel }
        switch slot {
        case .home: return hasScores ? homeTitle : data.popularLabel
        case .productDetail: return "Goes great with"
        case .cart: return "Complete your meal"
        case .confirmation: return hasScores ? "Next time, try" : data.popularLabel
        }
    }

    // MARK: Strategies

    private func popularItems(excluding excluded: Set<String>) -> [RecoItem] {
        data.popular.filter { !excluded.contains($0.id) }
            .map { RecoItem(product: $0, reason: "", kind: .popular, score: score(of: $0)) }
    }

    /// Top items from the highest scoring subcategories and categories, plus pairings and
    /// related items for recently viewed products. Every reason comes from the user's own activity.
    private func personalised(excluding excluded: Set<String>) -> [RecoItem] {
        var best: [String: RecoItem] = [:]
        var signals: [String: Int] = [:]
        func offer(_ p: Product, _ score: Double, _ reason: String, _ kind: RecoItem.Kind) {
            guard !excluded.contains(p.id), score > 0 else { return }
            signals[p.id, default: 0] += 1
            if let current = best[p.id], current.score >= score { return }
            best[p.id] = RecoItem(product: p, reason: reason, kind: kind, score: score)
        }

        let recent = state.recentViews.compactMap { catalog.product($0) }
        let recentSet = Set(state.recentViews.prefix(3))

        // 1. Related to recently viewed items (same subcategory or the same named range, for example Rasa Malaysia).
        for (rank, viewed) in recent.prefix(3).enumerated() {
            let recency = 1.0 / Double(rank + 1)
            let themeScore = (state.subcategory[subcategoryKey(viewed)] ?? 0) + recency
            for p in relatedProducts(to: viewed) where !recentSet.contains(p.id) {
                offer(p, themeScore + 0.2 * score(of: p), "Because you viewed \(viewed.name)", .viewed)
            }
            // 2. Pairings for recently viewed items.
            let pairScore = 0.6 * (state.product[viewed.id] ?? 0) + 0.5 * recency
            for p in data.pairings(for: viewed) {
                offer(p, pairScore + 0.2 * score(of: p), "Goes great with \(viewed.name)", .pairing)
            }
        }

        // 3. Top subcategories.
        for (sub, subScore) in state.subcategory.sorted(by: { $0.value > $1.value }).prefix(3) {
            for p in catalog.products where subcategoryKey(p) == sub {
                let penalty = recentSet.contains(p.id) ? 0.5 : 1.0
                offer(p, (0.9 * subScore + 0.3 * score(of: p)) * penalty, "More from \(p.subcategory)", .subcategory)
            }
        }

        // 4. Top categories.
        for (cat, catScore) in state.category.sorted(by: { $0.value > $1.value }).prefix(2) {
            let name = catalog.category(cat)?.name ?? cat
            for p in catalog.products(in: cat) {
                let penalty = recentSet.contains(p.id) ? 0.5 : 1.0
                offer(p, (0.5 * catScore + 0.3 * score(of: p)) * penalty, "More from \(name)", .category)
            }
        }

        // Items backed by more than one signal get a small boost.
        let ranked = best.values.map { item -> RecoItem in
            let bonus = 0.15 * Double(max(0, (signals[item.id] ?? 1) - 1))
            return RecoItem(product: item.product, reason: item.reason, kind: item.kind, score: (item.score + bonus).rounded2)
        }
        return ranked.sorted { $0.score == $1.score ? $0.product.name < $1.product.name : $0.score > $1.score }
    }

    private func pairingItems(for product: Product, excluding excluded: Set<String>) -> [RecoItem] {
        data.pairings(for: product)
            .filter { !excluded.contains($0.id) }
            .enumerated()
            .map { i, p in RecoItem(product: p, reason: "Goes great with \(product.name)", kind: .pairing,
                                    score: (score(of: p) + 0.01 * Double(10 - min(i, 10))).rounded2) }
            .sorted { $0.score > $1.score }
    }

    /// Pairings for the cart. Drinks lead when the cart has no drink, then sides when it has no side.
    private func completeYourMeal(cart: [CartItem], excluding excluded: Set<String>) -> [RecoItem] {
        guard let anchor = cart.first?.product else { return [] }
        var seen = Set<String>()
        var items: [RecoItem] = []
        for line in cart {
            for p in data.pairings(for: line.product) where !excluded.contains(p.id) && seen.insert(p.id).inserted {
                items.append(RecoItem(product: p, reason: "Goes great with \(line.product.name)", kind: .pairing, score: score(of: p).rounded2))
            }
        }
        let hasDrink = cart.contains { $0.product.category == "beverages" }
        let hasSide = cart.contains { $0.product.category == "sides" }
        if !hasDrink && !items.contains(where: { $0.product.category == "beverages" }) {
            for p in catalog.products(in: "beverages").prefix(2) where !excluded.contains(p.id) && seen.insert(p.id).inserted {
                items.append(RecoItem(product: p, reason: "Goes great with \(anchor.name)", kind: .pairing, score: score(of: p).rounded2))
            }
        }
        func rank(_ p: Product) -> Int {
            if !hasDrink && p.category == "beverages" { return 0 }
            if !hasSide && p.category == "sides" { return 1 }
            return 2
        }
        return items.enumerated()
            .sorted { a, b in
                let ra = rank(a.element.product), rb = rank(b.element.product)
                if ra != rb { return ra < rb }
                if a.element.score != b.element.score { return a.element.score > b.element.score }
                return a.offset < b.offset
            }
            .map(\.element)
    }

    /// Pinned IDs from the reco_pinned_ids variable always come first. Unknown IDs are ignored.
    private func withPinned(_ pinnedIds: String, _ items: [RecoItem]) -> [RecoItem] {
        let ids = pinnedIds.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        var seen = Set<String>()
        let pinned = ids.compactMap { catalog.product($0) }.filter { seen.insert($0.id).inserted }
            .map { RecoItem(product: $0, reason: "", kind: .pinned, score: score(of: $0)) }
        return pinned + items.filter { !seen.contains($0.id) }
    }

    // MARK: Helpers

    /// Pizza subcategories are kept apart from same-named ranges in other categories.
    private func subcategoryKey(_ p: Product) -> String { p.subcategory }

    /// Same subcategory, or the same named range across categories (first two words of a
    /// subcategory with three or more words, for example "Rasa Malaysia" Pizza, Pasta and Melts).
    private func relatedProducts(to product: Product) -> [Product] {
        let theme = Self.theme(of: product.subcategory)
        return catalog.products.filter { $0.subcategory == product.subcategory || (!theme.isEmpty && Self.theme(of: $0.subcategory) == theme) }
    }

    private static func theme(of subcategory: String) -> String {
        let words = subcategory.split(separator: " ")
        return words.count >= 3 ? words.prefix(2).joined(separator: " ").lowercased() : ""
    }

    private func pushTopAffinityIfChanged() {
        guard !suppressAffinityPush, let top = state.subcategory.max(by: { $0.value < $1.value })?.key, top != state.lastTopAffinity else { return }
        state.lastTopAffinity = top
        save()
        Analytics.setProfile([.topAffinity: top])
    }

    private func save() {
        if let raw = try? JSONEncoder().encode(state) { UserDefaults.standard.set(raw, forKey: Self.stateKey) }
    }
}

// MARK: Persona warm start

extension RecoEngine {
    /// A distinct preloaded history per demo persona, so Home differs immediately after login.
    enum WarmStart {
        case familyFeaster, lunchRegular, dealHunter

        /// (product ID, signal, units, size name)
        fileprivate var history: [(String, Signal, Int, String?)] {
            switch self {
            case .familyFeaster:
                return [
                    ("super-supreme-q2", .viewed, 1, nil), ("super-supreme-q2", .customised, 1, "Large"), ("super-supreme-q2", .orderedUnit, 2, "Large"),
                    ("meat-mania-p9", .viewed, 1, nil), ("meat-mania-p9", .addedToCart, 1, "Large"),
                    ("huts-signature-meat-mania-hs2", .viewed, 1, nil), ("huts-signature-meat-mania-hs2", .customised, 1, "Large"),
                    ("huts-signature-golden-shrimp-hs3", .viewed, 1, nil),
                    ("garlic-bread-gab", .addedToCart, 2, nil), ("krispy-wings-bbq-kwt2", .addedToCart, 1, nil),
                    ("huts-cheesy-lava-triple-cheese-bites-clav1", .viewed, 1, nil),
                ]
            case .lunchRegular:
                return [
                    ("mybox-melts-mybmelts", .viewed, 1, nil), ("mybox-melts-mybmelts", .orderedUnit, 1, nil),
                    ("mybox-pizza-mybox", .viewed, 1, nil), ("mybox-of-the-day-mybtheday", .addedToCart, 1, nil),
                    ("chicken-mania-m2", .viewed, 1, nil), ("tom-yum-chicken-m12", .addedToCart, 1, nil),
                    ("burger-chicken-m13", .viewed, 1, nil),
                ]
            case .dealHunter:
                return [
                    ("2nd-pizza-6-90-ltomerdeka5", .viewed, 1, nil), ("2nd-pizza-6-90-ltomerdeka5", .addedToCart, 1, nil),
                    ("2-regular-pizzas-for-rm-22-appdeal3", .viewed, 1, nil), ("2-regular-pizzas-for-rm-22-appdeal3", .orderedUnit, 1, nil),
                    ("2-pizzas-half-price-deal-halfdeal1", .viewed, 1, nil), ("2-pizzas-deal-rasa-malaysia-ltomerdeka6", .viewed, 1, nil),
                    ("my-box-fanta-combo-myboxfanta", .viewed, 1, nil),
                ]
            }
        }
    }

    /// Replaces the current history with the persona's preloaded history.
    func warmStart(_ profile: WarmStart) {
        reset()
        suppressAffinityPush = true
        for (id, signal, units, size) in profile.history {
            guard let p = catalog.product(id) else { continue }
            record(signal, p, units: units, size: size)
        }
        suppressAffinityPush = false
        pushTopAffinityIfChanged()
        // Warm-start orders are history, not this session's order.
        orderedThisSession = []
    }
}
