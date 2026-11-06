import Foundation

/// Places a mock order: records Order Placed, redeems the coupon and credits wallet 1460.
enum OrderService {
    static func pointsFor(amount: Double) -> Int { Int((amount * DemoConfig.pointsPerRinggit).rounded(.down)) }

    @MainActor
    static func place(cart: CartStore, session: SessionStore, orders: OrderStore,
                      payment: String, address: String, threshold: Double) async -> PlacedOrder {
        let orderId = PlacedOrder.newId()
        let identity = session.user?.identity
        let amount = cart.total(threshold: threshold)
        let points = identity == nil ? 0 : pointsFor(amount: amount)
        let couponCode = cart.appliedCoupon?.code
        let couponOrder = cart.couponOrder(orderId: orderId, status: "completed", payment: payment)

        var order = PlacedOrder(
            id: orderId, items: cart.items, mode: cart.orderMode, store: cart.selectedStore, address: address,
            subtotal: cart.subtotal, discount: cart.discount, deliveryFee: cart.deliveryFee(threshold: threshold),
            amount: amount, paymentMethod: payment, couponCode: couponCode, placedAt: Date(),
            pointsEarned: nil, pointsMessage: nil)

        // Items as a nested array of objects (iOS SDK 7.5.0+, Ingesting Nested Objects via SDKs).
        // Source stays on each line so recommendation-driven revenue can be measured.
        let items: [[String: Any]] = order.items.map {
            var item: [String: Any] = [
                "Product ID": $0.product.id,
                "Product Name": $0.product.name,
                "Category": $0.product.categoryName,
                "Quantity": $0.quantity,
                "Unit Price": $0.unitPrice,
                "Size": $0.size?.name ?? "",
                "Crust": $0.crust?.name ?? "",
                "Source": $0.source,
            ]
            if let slot = $0.recoSlot { item["Slot"] = slot.rawValue }
            return item
        }
        for line in order.items { RecoEngine.shared.record(.orderedUnit, line.product, units: line.quantity, size: line.size?.name) }
        Analytics.track(.orderPlaced, [
            "Order ID": orderId,
            "Amount": amount,
            "Discount": order.discount,
            "Payment Method": payment,
            "Order Mode": order.mode.rawValue,
            "Item Count": cart.itemCount,
            "Points Earned": points,
            "Items": items,
        ])
        session.recordOrder(value: amount, payment: payment, coupon: couponCode)

        if let identity {
            if let couponCode {
                do { _ = try await PromoAPI.shared.redeem(code: couponCode, identity: identity, order: couponOrder) }
                catch { NSLog("[Order] coupon redeem failed: %@", error.localizedDescription) }
            }
            if points > 0 {
                do {
                    _ = try await PromoAPI.shared.credit(identity: identity, points: Double(points), orderId: orderId,
                                                         saleAmount: amount, locationId: order.store?.id)
                    order.pointsEarned = points
                    order.pointsMessage = "You earned \(points) points"
                } catch {
                    order.pointsEarned = 0
                    order.pointsMessage = "Your \(points) points will appear in My Rewards shortly."
                }
            }
        } else {
            order.pointsMessage = "Log in next time to earn points on every order."
        }

        orders.add(order)
        cart.clear()
        return order
    }
}
