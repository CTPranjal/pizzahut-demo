import Foundation

enum OrderMode: String, CaseIterable, Identifiable, Codable {
    case delivery = "Delivery"
    case takeaway = "Takeaway"
    var id: String { rawValue }
}

struct CartItem: Identifiable, Hashable {
    let id = UUID()
    let product: Product
    var size: Catalog.PizzaOptions.Option?
    var crust: Catalog.PizzaOptions.Option?
    var toppings: [Catalog.PizzaOptions.Option] = []
    var quantity: Int
    /// "Recommendation" when added from a recommendation row, otherwise "Browse". Kept through to Order Placed.
    var source = "Browse"
    var recoSlot: RecoSlot?

    var unitPrice: Double {
        let extras = (size?.add ?? 0) + (crust?.add ?? 0) + toppings.reduce(0) { $0 + $1.add }
        return (product.price + extras).rounded2
    }
    var lineTotal: Double { (unitPrice * Double(quantity)).rounded2 }

    var optionsSummary: String {
        var parts: [String] = []
        if let size { parts.append(size.name) }
        if let crust { parts.append(crust.name) }
        if !toppings.isEmpty { parts.append("Extra " + toppings.map(\.name).joined(separator: ", ")) }
        return parts.joined(separator: " · ")
    }
}

struct AppliedCoupon: Equatable {
    let code: String
    let couponId: Int?
    let discount: Double
    let description: String
}

final class CartStore: ObservableObject {
    @Published private(set) var items: [CartItem] = []
    @Published var orderMode: OrderMode {
        didSet { UserDefaults.standard.set(orderMode.rawValue, forKey: "orderMode") }
    }
    @Published var selectedStore: Catalog.Store? {
        didSet { UserDefaults.standard.set(selectedStore?.id, forKey: "storeId") }
    }
    @Published var appliedCoupon: AppliedCoupon?
    /// A coupon chosen on the Rewards screen, validated when the cart opens.
    @Published var pendingCouponCode: String?

    init() {
        orderMode = OrderMode(rawValue: UserDefaults.standard.string(forKey: "orderMode") ?? "") ?? .delivery
        if let id = UserDefaults.standard.string(forKey: "storeId") {
            selectedStore = Catalog.shared.store(id)
        }
    }

    var itemCount: Int { items.reduce(0) { $0 + $1.quantity } }
    var subtotal: Double { items.reduce(0) { $0 + $1.lineTotal }.rounded2 }
    var discount: Double { min(appliedCoupon?.discount ?? 0, subtotal) }

    func deliveryFee(threshold: Double) -> Double {
        guard orderMode == .delivery, !items.isEmpty else { return 0 }
        return subtotal >= threshold ? 0 : DemoConfig.deliveryFee
    }

    func total(threshold: Double) -> Double {
        max(0, subtotal - discount + deliveryFee(threshold: threshold)).rounded2
    }

    func add(_ item: CartItem) {
        if let idx = items.firstIndex(where: { $0.product.id == item.product.id && $0.size == item.size && $0.crust == item.crust && $0.toppings == item.toppings }) {
            items[idx].quantity += item.quantity
        } else {
            items.append(item)
        }
        invalidateCoupon()
    }

    func setQuantity(_ item: CartItem, _ quantity: Int) {
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else { return }
        if quantity <= 0 { items.remove(at: idx) } else { items[idx].quantity = quantity }
        invalidateCoupon()
    }

    func remove(_ item: CartItem) {
        items.removeAll { $0.id == item.id }
        invalidateCoupon()
    }

    func clear() {
        items = []
        appliedCoupon = nil
        pendingCouponCode = nil
    }

    /// The cart changed, so a previously validated coupon must be validated again.
    private func invalidateCoupon() {
        if let code = appliedCoupon?.code {
            appliedCoupon = nil
            pendingCouponCode = code
        }
    }
}

extension Double {
    var rounded2: Double { (self * 100).rounded() / 100 }
    var rm: String { String(format: "RM %.2f", self) }
}
