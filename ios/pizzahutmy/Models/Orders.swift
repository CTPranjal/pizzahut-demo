import Foundation

struct PlacedOrder: Identifiable, Hashable {
    let id: String
    let items: [CartItem]
    let mode: OrderMode
    let store: Catalog.Store?
    let address: String
    let subtotal: Double
    let discount: Double
    let deliveryFee: Double
    let amount: Double
    let paymentMethod: String
    let couponCode: String?
    let placedAt: Date
    var pointsEarned: Int?
    var pointsMessage: String?

    static func == (l: PlacedOrder, r: PlacedOrder) -> Bool { l.id == r.id }
    func hash(into h: inout Hasher) { h.combine(id) }

    static func newId() -> String {
        "PHM" + String(Int(Date().timeIntervalSince1970) % 100_000_000) + String(Int.random(in: 10...99))
    }

    /// Mock tracking statuses, advanced by time since the order was placed.
    var statuses: [String] {
        mode == .delivery
            ? ["Order Received", "Preparing", "Baking", "Out for Delivery", "Delivered"]
            : ["Order Received", "Preparing", "Baking", "Ready for Takeaway", "Collected"]
    }

    func statusIndex(at now: Date = Date()) -> Int {
        // One step every 20 seconds so the flow can be shown on stage.
        min(statuses.count - 1, Int(now.timeIntervalSince(placedAt) / 20))
    }
}

final class OrderStore: ObservableObject {
    @Published var orders: [PlacedOrder] = []
    var latest: PlacedOrder? { orders.first }

    func add(_ order: PlacedOrder) { orders.insert(order, at: 0) }

    func update(_ order: PlacedOrder) {
        if let idx = orders.firstIndex(where: { $0.id == order.id }) { orders[idx] = order }
    }
}
