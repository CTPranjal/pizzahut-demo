import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var router: DeepLinkRouter
    @EnvironmentObject var pe: ProductExperience
    @EnvironmentObject var cart: CartStore

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                switch router.tab {
                case .home: HomeView()
                case .rewards: RewardsView()
                case .order: MenuView()
                case .offers: OffersView()
                case .profile: AccountView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            BottomBar()
        }
        .ignoresSafeArea(.keyboard)
        .sheet(item: $router.product) { ProductDetailView(product: $0, recoSlot: router.productRecoSlot) }
        .sheet(isPresented: $router.showCart) { CartView() }
        .sheet(isPresented: $router.showStores) { NavigationView { StoreLocatorView(source: "Deep Link", dismissible: true) } }
        .onChange(of: pe.showRewardsTab) { show in
            if !show && router.tab == .rewards { router.tab = .home }
        }
    }
}

/// Bottom bar mirroring the real app: Home, Rewards, raised red Order button, Offer, Profile.
struct BottomBar: View {
    @EnvironmentObject var router: DeepLinkRouter
    @EnvironmentObject var pe: ProductExperience

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            item(.home, "house", "Home")
            if pe.showRewardsTab { item(.rewards, "crown", "Rewards") }
            Button { router.tab = .order } label: {
                VStack(spacing: 2) {
                    ZStack {
                        Circle().fill(Theme.red).frame(width: 66, height: 66)
                            .shadow(color: Theme.red.opacity(0.35), radius: 6, y: 3)
                        VStack(spacing: 1) {
                            HutRoofShape().fill(Color.white).frame(width: 30, height: 12)
                            Text("Order").font(.system(size: 12, weight: .bold)).foregroundColor(.white)
                        }
                    }
                    .offset(y: -16)
                }
                .frame(maxWidth: .infinity)
            }
            .accessibilityLabel("Order")
            item(.offers, "percent", "Offer")
            item(.profile, "person", "Profile")
        }
        .frame(height: 58)
        .padding(.bottom, 2)
        .background(Color.white.shadow(color: .black.opacity(0.08), radius: 6, y: -2).ignoresSafeArea(edges: .bottom))
    }

    private func item(_ tab: AppTab, _ icon: String, _ title: String) -> some View {
        let selected = router.tab == tab
        return Button { router.tab = tab } label: {
            VStack(spacing: 4) {
                Rectangle().fill(selected ? Theme.red : .clear).frame(height: 2.5)
                Image(systemName: selected ? icon + ".fill" : icon).font(.system(size: 19))
                Text(title).font(.system(size: 11, weight: selected ? .bold : .medium))
                Spacer(minLength: 0)
            }
            .foregroundColor(selected ? Theme.red : Theme.grey)
            .frame(maxWidth: .infinity)
            .background(selected ? Theme.redTint.opacity(0.35) : .clear)
        }
    }
}

/// The Pizza Hut red roof silhouette, drawn as a simple trapezoid with a wide brim.
struct HutRoofShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX + r.width * 0.22, y: r.minY + r.height * 0.45))
        p.addLine(to: CGPoint(x: r.minX + r.width * 0.30, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX - r.width * 0.30, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX - r.width * 0.22, y: r.minY + r.height * 0.45))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

/// Floating cart pill shown above the bottom bar when the cart has items.
struct CartPill: View {
    @EnvironmentObject var cart: CartStore
    @EnvironmentObject var router: DeepLinkRouter
    var body: some View {
        if cart.itemCount > 0 {
            Button { router.showCart = true } label: {
                HStack {
                    Image(systemName: "cart.fill")
                    Text("\(cart.itemCount) item\(cart.itemCount == 1 ? "" : "s")")
                    Spacer()
                    Text("View Cart · " + cart.subtotal.rm).fontWeight(.bold)
                }
                .font(Theme.body(15, .semibold)).foregroundColor(.white)
                .padding(.horizontal, 18).frame(height: 50)
                .background(Theme.red).clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.18), radius: 8, y: 3)
            }
            .padding(.horizontal, 16).padding(.bottom, 8)
        }
    }
}
