import SwiftUI

struct CheckoutView: View {
    let onFinished: () -> Void
    @EnvironmentObject var cart: CartStore
    @EnvironmentObject var session: SessionStore
    @EnvironmentObject var orders: OrderStore
    @EnvironmentObject var pe: ProductExperience

    /// Mock payment options. No real payment is taken.
    static let paymentMethods = ["Credit / Debit Card", "Touch 'n Go eWallet", "GrabPay", "Cash"]

    @State private var payment = CheckoutView.paymentMethods[0]
    @State private var address = ""
    @State private var placing = false
    @State private var placed: PlacedOrder?
    @State private var showStores = false

    private var canPlace: Bool {
        guard !cart.items.isEmpty, !placing else { return false }
        if cart.orderMode == .delivery { return !address.trimmingCharacters(in: .whitespaces).isEmpty }
        return cart.selectedStore != nil
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 14) {
                    section("Order mode") { OrderModeToggle() }
                    if cart.orderMode == .delivery {
                        section("Delivery address") {
                            TextField("House number, street, area, postcode", text: $address)
                                .padding(.horizontal, 12).frame(height: 46)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border))
                            storeRow(label: "Delivering from")
                        }
                    } else {
                        section("Takeaway from") { storeRow(label: "Store") }
                    }
                    section("Payment") {
                        ForEach(Self.paymentMethods, id: \.self) { m in
                            Button { payment = m } label: {
                                HStack {
                                    Image(systemName: payment == m ? "largecircle.fill.circle" : "circle").foregroundColor(payment == m ? Theme.red : Theme.greyLight)
                                    Text(m).foregroundColor(Theme.text)
                                    Spacer()
                                }
                                .font(Theme.body(15)).padding(.vertical, 6)
                            }
                        }
                        Text("Demo checkout. No payment is taken.").font(Theme.body(12)).foregroundColor(Theme.greyLight)
                    }
                    section("Summary") {
                        let t = pe.freeDeliveryThreshold
                        line("Items (\(cart.itemCount))", cart.subtotal.rm)
                        if cart.discount > 0 { line("Coupon \(cart.appliedCoupon?.code ?? "")", "- " + cart.discount.rm) }
                        if cart.orderMode == .delivery { line("Delivery fee", cart.deliveryFee(threshold: t) == 0 ? "FREE" : cart.deliveryFee(threshold: t).rm) }
                        Divider()
                        line("Total", cart.total(threshold: t).rm, bold: true)
                        if session.isLoggedIn {
                            Label("You will earn \(OrderService.pointsFor(amount: cart.total(threshold: t))) points", systemImage: "star.circle.fill")
                                .font(Theme.body(13, .semibold)).foregroundColor(Theme.red)
                        }
                    }
                }
                .padding(.vertical, 14)
            }
            NavigationLink(destination: placed.map { OrderConfirmationView(order: $0, onDone: onFinished) }, isActive: Binding(
                get: { placed != nil }, set: { if !$0 { placed = nil } })) { EmptyView() }
            Button {
                placeOrder()
            } label: {
                if placing { ProgressView().tint(.white) } else { Text("Place Order · " + cart.total(threshold: pe.freeDeliveryThreshold).rm) }
            }
            .buttonStyle(PrimaryButtonStyle(enabled: canPlace))
            .disabled(!canPlace)
            .padding(16)
            .background(Color.white.shadow(color: .black.opacity(0.06), radius: 4, y: -2))
        }
        .background(Theme.surface.ignoresSafeArea())
        .navigationTitle("Checkout")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showStores) { NavigationView { StoreLocatorView(source: "Checkout", dismissible: true) } }
        .onAppear {
            if address.isEmpty { address = session.deliveryAddress }
            Analytics.track(.checkoutStarted, ["Item Count": cart.itemCount, "Cart Value": cart.subtotal, "Order Mode": cart.orderMode.rawValue])
        }
    }

    private func placeOrder() {
        placing = true
        if cart.orderMode == .delivery { session.deliveryAddress = address }
        Task { @MainActor in
            let order = await OrderService.place(cart: cart, session: session, orders: orders, payment: payment,
                                                 address: cart.orderMode == .delivery ? address : "",
                                                 threshold: pe.freeDeliveryThreshold)
            placing = false
            placed = order
        }
    }

    private func storeRow(label: String) -> some View {
        Button { showStores = true } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(label).font(Theme.body(12)).foregroundColor(Theme.grey)
                    Text(cart.selectedStore?.name ?? "Choose a Hut").font(Theme.body(15, .semibold)).foregroundColor(cart.selectedStore == nil ? Theme.red : Theme.ink)
                }
                Spacer()
                Text("Change").font(Theme.body(13, .semibold)).foregroundColor(Theme.red)
            }
        }
    }

    private func section<C: View>(_ title: String, @ViewBuilder _ content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(Theme.body(15, .bold)).foregroundColor(Theme.ink)
            content()
        }
        .padding(14).frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white).clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 16)
    }

    private func line(_ l: String, _ r: String, bold: Bool = false) -> some View {
        HStack { Text(l).font(Theme.body(14, bold ? .bold : .regular)); Spacer(); Text(r).font(Theme.body(bold ? 17 : 14, bold ? .bold : .medium)) }
    }
}

struct OrderConfirmationView: View {
    let order: PlacedOrder
    let onDone: () -> Void
    @EnvironmentObject var orders: OrderStore

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Image(systemName: "checkmark.circle.fill").font(.system(size: 64)).foregroundColor(Theme.success).padding(.top, 30)
                Text("Order placed!").font(Theme.heading(28)).foregroundColor(Theme.ink)
                Text("Order \(order.id)").font(Theme.body(15, .semibold)).foregroundColor(Theme.grey)
                if let msg = order.pointsMessage {
                    HStack(spacing: 10) {
                        CatalogImageView(path: Catalog.shared.icons["rewards"]).frame(width: 36, height: 36)
                        Text(msg).font(Theme.body(16, .bold)).foregroundColor(order.pointsEarned ?? 0 > 0 ? Theme.red : Theme.text)
                        Spacer()
                    }
                    .padding(14).background(Theme.redTint.opacity(0.35)).clipShape(RoundedRectangle(cornerRadius: 14))
                }
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(order.items) { i in
                        HStack { Text("\(i.quantity) x \(i.product.name)").font(Theme.body(14)); Spacer(); Text(i.lineTotal.rm).font(Theme.body(14, .medium)) }
                    }
                    Divider()
                    HStack { Text("Paid with \(order.paymentMethod)").font(Theme.body(13)).foregroundColor(Theme.grey); Spacer(); Text(order.amount.rm).font(Theme.body(17, .bold)) }
                }
                .padding(14).background(Color.white).clipShape(RoundedRectangle(cornerRadius: 14))
                NavigationLink(destination: OrderTrackingView(orderId: order.id)) { Text("Track my order") }
                    .buttonStyle(PrimaryButtonStyle())
                Button("Back to home", action: onDone).font(Theme.body(15, .semibold)).foregroundColor(Theme.red)
                RecoRowView(slot: .confirmation, tapAction: .closeThenOpen(onDone))
                    .padding(.horizontal, -16)
            }
            .padding(16)
        }
        .background(Theme.surface.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .navigationTitle("Confirmation")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct OrderTrackingView: View {
    let orderId: String
    @EnvironmentObject var orders: OrderStore
    @State private var now = Date()
    @State private var lastTracked = -1
    private let timer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()

    var body: some View {
        Group {
            if let order = orders.orders.first(where: { $0.id == orderId }) {
                let current = order.statusIndex(at: now)
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(order.statuses[current]).font(Theme.heading(24)).foregroundColor(Theme.ink).padding(.bottom, 4)
                        Text(order.mode == .delivery ? "Delivering to \(order.address)" : "Takeaway from \(order.store?.name ?? "your Hut")")
                            .font(Theme.body(13)).foregroundColor(Theme.grey).padding(.bottom, 20)
                        ForEach(order.statuses.indices, id: \.self) { i in
                            HStack(alignment: .top, spacing: 14) {
                                VStack(spacing: 0) {
                                    Circle().fill(i <= current ? Theme.red : Theme.border).frame(width: 18, height: 18)
                                        .overlay(Image(systemName: "checkmark").font(.system(size: 9, weight: .bold)).foregroundColor(.white).opacity(i <= current ? 1 : 0))
                                    if i < order.statuses.count - 1 {
                                        Rectangle().fill(i < current ? Theme.red : Theme.border).frame(width: 3, height: 42)
                                    }
                                }
                                Text(order.statuses[i]).font(Theme.body(15, i == current ? .bold : .regular))
                                    .foregroundColor(i <= current ? Theme.ink : Theme.greyLight)
                            }
                        }
                        Text("Demo tracking: the status moves forward every 20 seconds.").font(Theme.body(12)).foregroundColor(Theme.greyLight).padding(.top, 20)
                    }
                    .padding(20)
                }
                .onAppear { track(order, current) }
                .onChange(of: current) { track(order, $0) }
            } else {
                EmptyStateCard(icon: "bag", title: "Order not found", message: "This order is no longer available.").padding()
            }
        }
        .background(Theme.surface.ignoresSafeArea())
        .navigationTitle("Track Order")
        .navigationBarTitleDisplayMode(.inline)
        .onReceive(timer) { now = $0 }
    }

    private func track(_ order: PlacedOrder, _ index: Int) {
        guard index != lastTracked else { return }
        lastTracked = index
        Analytics.track(.orderTracked, ["Order ID": order.id, "Status": order.statuses[index]])
    }
}
