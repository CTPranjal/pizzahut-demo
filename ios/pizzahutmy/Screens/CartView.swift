import SwiftUI

struct CartView: View {
    @EnvironmentObject var cart: CartStore
    @EnvironmentObject var session: SessionStore
    @EnvironmentObject var pe: ProductExperience
    @EnvironmentObject var router: DeepLinkRouter
    @Environment(\.dismiss) private var dismiss

    @State private var couponInput = ""
    @State private var couponMessage: String?
    @State private var couponOK = false
    @State private var validating = false
    @State private var goCheckout = false
    @State private var showLogin = false

    var body: some View {
        NavigationView {
            Group {
                if cart.items.isEmpty && !goCheckout {
                    EmptyStateCard(icon: "cart", title: "Your cart is empty", message: "Add a pizza, a MyBox or a deal to get started.",
                                   action: ("Browse menu", { dismiss(); router.tab = .order }))
                        .padding(16)
                    Spacer()
                } else {
                    content
                }
            }
            .background(Theme.surface.ignoresSafeArea())
            .navigationTitle("My Cart")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Close") { dismiss() }.foregroundColor(Theme.ink) } }
        }
        .navigationViewStyle(.stack)
        .sheet(isPresented: $showLogin) { NavigationView { LoginView(onDone: { showLogin = false }) } }
        .onAppear {
            Analytics.track(.cartViewed, ["Item Count": cart.itemCount, "Cart Value": cart.subtotal])
            if let pending = cart.pendingCouponCode {
                couponInput = pending
                cart.pendingCouponCode = nil
                applyCoupon()
            } else if let applied = cart.appliedCoupon {
                couponInput = applied.code
                couponOK = true
                couponMessage = "\(applied.code) applied. You save \(applied.discount.rm)."
            }
        }
    }

    private var content: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 14) {
                    modeRow
                    freeDeliveryBar
                    VStack(spacing: 0) {
                        ForEach(cart.items) { item in
                            CartLine(item: item)
                            if item.id != cart.items.last?.id { Divider().padding(.leading, 86) }
                        }
                    }
                    .background(Color.white).clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 16)

                    // With recommendations on, the "Complete your meal" row is the fallback content;
                    // with reco_strategy "off" the static upsell keeps the slot from looking empty.
                    DisplaySlotView(slot: .cartUpsell, height: 110) {
                        if pe.recoStrategy == .off { upsellFallback }
                    }
                    RecoRowView(slot: .cart, tapAction: .addToCart)
                    couponBox
                    summary
                }
                .padding(.vertical, 14)
            }
            NavigationLink(destination: CheckoutView(onFinished: { dismiss() }), isActive: $goCheckout) { EmptyView() }
            Button("Checkout · " + cart.total(threshold: pe.freeDeliveryThreshold).rm) { goCheckout = true }
                .buttonStyle(PrimaryButtonStyle())
                .padding(16)
                .background(Color.white.shadow(color: .black.opacity(0.06), radius: 4, y: -2))
        }
    }

    private var modeRow: some View {
        HStack {
            Image(systemName: cart.orderMode == .delivery ? "bicycle" : "bag").foregroundColor(Theme.red)
            Text(cart.orderMode.rawValue).font(Theme.body(15, .bold))
            Text(cart.selectedStore.map { "· \($0.name)" } ?? "").font(Theme.body(13)).foregroundColor(Theme.grey).lineLimit(1)
            Spacer()
        }
        .padding(.horizontal, 16)
    }

    /// Progress toward the free delivery threshold (Product Experiences variable).
    @ViewBuilder private var freeDeliveryBar: some View {
        if cart.orderMode == .delivery {
            let threshold = pe.freeDeliveryThreshold
            let progress = threshold > 0 ? min(1, cart.subtotal / threshold) : 1
            VStack(alignment: .leading, spacing: 8) {
                if progress >= 1 {
                    Label("You have unlocked free delivery", systemImage: "checkmark.seal.fill")
                        .font(Theme.body(14, .semibold)).foregroundColor(Theme.success)
                } else {
                    (Text("Add ") + Text((threshold - cart.subtotal).rm).bold() + Text(" more for free delivery"))
                        .font(Theme.body(14)).foregroundColor(Theme.text)
                }
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Theme.border)
                        Capsule().fill(progress >= 1 ? Theme.success : Theme.red).frame(width: g.size.width * progress)
                    }
                }
                .frame(height: 8)
            }
            .padding(14).background(Color.white).clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, 16)
        }
    }

    /// Fallback for cart_upsell: a real side that is not in the cart yet.
    @ViewBuilder private var upsellFallback: some View {
        let names = ["Garlic Bread", "Hut's Cheesy Lava Triple Cheese Bites", "Krispy Fries"]
        let candidates = names.compactMap { n in Catalog.shared.products(in: "sides").first { $0.name == n } }
        if let p = (candidates + Catalog.shared.products(in: "sides")).first(where: { p in !cart.items.contains { $0.product.id == p.id } }) {
            HStack(spacing: 12) {
                CatalogImageView(path: p.image, mode: .fit).frame(width: 70, height: 70).background(Color.white).clipShape(RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 3) {
                    Text("Complete your meal").font(Theme.body(12, .heavy)).foregroundColor(Theme.red)
                    Text(p.name).font(Theme.body(15, .bold)).foregroundColor(Theme.ink).lineLimit(1)
                    Text(p.price.rm).font(Theme.body(13, .semibold)).foregroundColor(Theme.grey)
                }
                Spacer()
                Button("Add") {
                    cart.add(CartItem(product: p, quantity: 1))
                    RecoEngine.shared.record(.addedToCart, p)
                    Analytics.track(.addedToCart, ["Product ID": p.id, "Product Name": p.name, "Category": p.categoryName,
                                                   "Price": p.price, "Quantity": 1, "Cart Value": cart.subtotal, "Source": "Browse"])
                }
                .buttonStyle(OutlineButtonStyle())
            }
            .padding(12).background(Theme.redTint.opacity(0.3)).clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, 16)
        }
    }

    private var couponBox: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Coupon").font(Theme.body(15, .bold))
            if session.isLoggedIn {
                HStack {
                    TextField("Enter coupon code", text: $couponInput)
                        .textInputAutocapitalization(.characters).disableAutocorrection(true)
                        .padding(.horizontal, 12).frame(height: 44)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border))
                    if cart.appliedCoupon != nil {
                        Button("Remove") { removeCoupon() }.buttonStyle(OutlineButtonStyle())
                    } else {
                        Button { applyCoupon() } label: {
                            if validating { ProgressView().frame(width: 52) } else { Text("Apply") }
                        }
                        .buttonStyle(OutlineButtonStyle())
                        .disabled(couponInput.trimmingCharacters(in: .whitespaces).isEmpty || validating)
                    }
                }
                if let couponMessage {
                    Label(couponMessage, systemImage: couponOK ? "checkmark.circle.fill" : "exclamationmark.circle")
                        .font(Theme.body(13)).foregroundColor(couponOK ? Theme.success : Theme.red)
                }
            } else {
                HStack {
                    Text("Log in to use coupons and earn points on this order.").font(Theme.body(13)).foregroundColor(Theme.grey)
                    Spacer()
                    Button("Log in") { showLogin = true }.buttonStyle(OutlineButtonStyle())
                }
            }
        }
        .padding(14).background(Color.white).clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 16)
    }

    private var summary: some View {
        let t = pe.freeDeliveryThreshold
        return VStack(spacing: 8) {
            row("Subtotal", cart.subtotal.rm)
            if cart.discount > 0 { row("Coupon discount", "- " + cart.discount.rm, color: Theme.success) }
            if cart.orderMode == .delivery { row("Delivery fee", cart.deliveryFee(threshold: t) == 0 ? "FREE" : cart.deliveryFee(threshold: t).rm) }
            Divider()
            row("Total", cart.total(threshold: t).rm, bold: true)
            Text("Prices include 6% SST.").font(Theme.body(11)).foregroundColor(Theme.greyLight).frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(14).background(Color.white).clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 16)
    }

    private func row(_ l: String, _ r: String, bold: Bool = false, color: Color = Theme.text) -> some View {
        HStack {
            Text(l).font(Theme.body(14, bold ? .bold : .regular))
            Spacer()
            Text(r).font(Theme.body(bold ? 17 : 14, bold ? .bold : .medium)).foregroundColor(bold ? Theme.ink : color)
        }
    }

    // MARK: Coupon validation (Validate Coupon API) before applying

    private func applyCoupon() {
        let code = couponInput.trimmingCharacters(in: .whitespaces).uppercased()
        guard !code.isEmpty, let identity = session.user?.identity else { return }
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        validating = true
        couponMessage = nil
        let order = cart.couponOrder(orderId: "CART-" + UUID().uuidString.prefix(8), status: "pending", payment: nil)
        Task { @MainActor in
            defer { validating = false }
            do {
                let coupon = try await PromoAPI.shared.validate(code: code, identity: identity, order: order)
                if coupon.isApplicable == true {
                    let discount = coupon.couponSavings?.orderDiscount ?? 0
                    cart.appliedCoupon = AppliedCoupon(code: code, couponId: coupon.couponCodeId, discount: discount, description: coupon.description ?? "")
                    couponOK = true
                    couponMessage = discount > 0 ? "\(code) applied. You save \(discount.rm)." : "\(code) applied."
                    Analytics.track(.couponApplied, ["Coupon Code": code, "Discount": discount, "Result": "Applied"])
                } else {
                    couponOK = false
                    couponMessage = PromoAPI.friendly(code: nil, message: coupon.message ?? "")
                    Analytics.track(.couponApplied, ["Coupon Code": code, "Discount": 0, "Result": "Not Applicable"])
                }
            } catch {
                couponOK = false
                couponMessage = error.localizedDescription
                Analytics.track(.couponApplied, ["Coupon Code": code, "Discount": 0, "Result": "Failed"])
            }
        }
    }

    private func removeCoupon() {
        cart.appliedCoupon = nil
        couponMessage = nil
        couponOK = false
        couponInput = ""
    }
}

struct CartLine: View {
    let item: CartItem
    @EnvironmentObject var cart: CartStore
    @State private var qty: Int = 1

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            CatalogImageView(path: item.product.image, mode: .fit).frame(width: 62, height: 62).background(Color.white).clipShape(RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 4) {
                Text(item.product.name).font(Theme.body(14, .bold)).foregroundColor(Theme.ink)
                if !item.optionsSummary.isEmpty { Text(item.optionsSummary).font(Theme.body(12)).foregroundColor(Theme.grey) }
                Text(item.lineTotal.rm).font(Theme.body(14, .semibold)).foregroundColor(Theme.red)
            }
            Spacer()
            QuantityStepper(value: $qty, min: 0) { newValue in
                let delta = item.quantity - newValue
                cart.setQuantity(item, newValue)
                if delta > 0 {
                    Analytics.track(.removedFromCart, ["Product ID": item.product.id, "Quantity": delta, "Cart Value": cart.subtotal])
                } else {
                    RecoEngine.shared.record(.addedToCart, item.product, units: -delta)
                    var props: [String: Any] = ["Product ID": item.product.id, "Product Name": item.product.name, "Category": item.product.categoryName,
                                                "Price": item.unitPrice, "Quantity": -delta, "Cart Value": cart.subtotal, "Source": item.source]
                    if let slot = item.recoSlot { props["Slot"] = slot.rawValue }
                    Analytics.track(.addedToCart, props)
                }
            }
        }
        .padding(12)
        .onAppear { qty = item.quantity }
    }
}
