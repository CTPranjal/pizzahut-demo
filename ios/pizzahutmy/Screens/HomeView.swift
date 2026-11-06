import SwiftUI

struct HomeView: View {
    @EnvironmentObject var router: DeepLinkRouter
    @EnvironmentObject var cart: CartStore
    @EnvironmentObject var session: SessionStore
    @EnvironmentObject var pe: ProductExperience
    @EnvironmentObject var inbox: InboxManager
    @State private var showPersonas = false
    @State private var showStores = false

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 18) {
                    header
                    greeting
                    DisplaySlotView(slot: .homeHero, height: 190) { BannerCarousel() }
                    headline
                    OrderModeToggle().padding(.horizontal, 16)
                    DisplaySlotView(slot: .homeStrip, height: 110) { featuredDealStrip }
                    RecoRowView(slot: .home, animateReorder: true)
                    highlights
                    exploreMenu
                    quickActions
                    footer
                }
                .padding(.bottom, cart.itemCount > 0 ? 80 : 20)
            }
            .background(Theme.surface.ignoresSafeArea())
            // Brand red behind the status bar once the header scrolls away.
            .safeAreaInset(edge: .top, spacing: 0) {
                Color.clear.frame(height: 0).background(Theme.red.ignoresSafeArea(edges: .top))
            }
            CartPill()
        }
        .sheet(isPresented: $showPersonas) { DemoPersonasView() }
        .sheet(isPresented: $showStores) { NavigationView { StoreLocatorView(source: "Home Header", dismissible: true) } }
        .onAppear {
            Analytics.track(.homeViewed, ["Order Mode": cart.orderMode.rawValue, "Store Name": cart.selectedStore?.name ?? "Not selected"])
        }
    }

    // MARK: Header (red, like the real app)

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                CatalogImageView(path: Catalog.shared.brand.logo)
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.6)))
                    .onLongPressGesture(minimumDuration: 0.8) { showPersonas = true }
                    .accessibilityLabel("Pizza Hut")
                Button { showStores = true } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Image(systemName: "mappin.circle")
                            Text("\(cart.orderMode.rawValue) Now").fontWeight(.bold)
                            Text(cart.orderMode == .delivery ? "to" : "from")
                            Text(cart.selectedStore?.name ?? "Select location")
                                .font(Theme.body(12, .semibold)).foregroundColor(Theme.red)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Color.white).clipShape(RoundedRectangle(cornerRadius: 4))
                                .lineLimit(1)
                        }
                        HStack(spacing: 3) {
                            Text("Get accurate menu and pricing")
                            Image(systemName: "chevron.down")
                        }.font(Theme.body(12)).opacity(0.9)
                    }
                    .font(Theme.body(14))
                    .foregroundColor(.white)
                }
                Spacer(minLength: 4)
                Button { InboxManager.shared.present() } label: {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "bell").font(.system(size: 21, weight: .semibold)).foregroundColor(.white).padding(4)
                        Badge(count: inbox.unreadCount).offset(x: 6, y: -4)
                    }
                }
                .accessibilityLabel("Inbox")
            }
        }
        .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 22)
        .background(RoundedCorner(radius: 22, corners: [.bottomLeft, .bottomRight]).fill(Theme.red).ignoresSafeArea(edges: .top))
    }

    private var greeting: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(timeGreeting), \(session.user?.name.components(separatedBy: " ").first ?? "there") 👋")
                .font(Theme.body(19, .bold)).foregroundColor(Theme.ink)
            HStack(spacing: 12) {
                summaryCard(title: "My Offers", value: "Coupons", icon: Catalog.shared.icons["offers"]) { router.tab = .offers }
                summaryCard(title: "My Rewards", value: session.isLoggedIn ? "View points" : "Log in", icon: Catalog.shared.icons["rewards"]) {
                    router.tab = pe.showRewardsTab ? .rewards : .profile
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, -6)
    }

    private func summaryCard(title: String, value: String, icon: String?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(Theme.body(13)).foregroundColor(Theme.grey)
                    Text(value).font(Theme.body(16, .bold)).foregroundColor(Theme.ink)
                }
                Spacer()
                CatalogImageView(path: icon).frame(width: 34, height: 34)
            }
            .padding(12)
            .background(Color.white).clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border))
        }
        .buttonStyle(.plain)
    }

    private var timeGreeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        return h < 12 ? "Good morning" : (h < 18 ? "Good afternoon" : "Good evening")
    }

    // MARK: Product Experiences driven headline

    private var headline: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text(pe.homeHeadline).font(Theme.heading(24)).foregroundColor(Theme.ink)
                Text(pe.homeSubheadline).font(Theme.body(14)).foregroundColor(Theme.grey)
            }
            Spacer()
            Button(pe.primaryCtaText) { router.tab = .order }
                .font(Theme.body(14, .bold)).foregroundColor(.white)
                .padding(.horizontal, 16).padding(.vertical, 10)
                .background(Theme.red).clipShape(Capsule())
        }
        .padding(.horizontal, 16)
    }

    /// Fallback for home_strip: the deal named by the featured_deal_id variable.
    @ViewBuilder private var featuredDealStrip: some View {
        if let p = Catalog.shared.product(pe.featuredDealId) ?? Catalog.shared.product(ProductExperience.Defaults.featuredDealId) {
            Button {
                Analytics.track(.dealViewed, ["Deal ID": p.id, "Deal Name": p.name, "Price": p.price])
                router.product = p
            } label: {
                HStack(spacing: 12) {
                    CatalogImageView(path: p.image, mode: .fill).frame(width: 96, height: 72).clipShape(RoundedRectangle(cornerRadius: 10))
                    VStack(alignment: .leading, spacing: 4) {
                        Text("FEATURED DEAL").font(Theme.body(11, .heavy)).foregroundColor(Theme.red)
                        Text(p.name).font(Theme.body(15, .bold)).foregroundColor(Theme.ink).lineLimit(2)
                        Text("From " + p.price.rm).font(Theme.body(14, .semibold)).foregroundColor(Theme.red)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").foregroundColor(Theme.grey)
                }
                .padding(10)
                .background(Color.white).clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.border))
                .padding(.horizontal, 16)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: Our Highlights (real highlight tiles)

    private var highlights: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(lead: "Our", accent: "Highlights", action: ("View More", { router.tab = .offers }))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Catalog.shared.deals) { deal in DealTile(deal: deal) }
                }.padding(.horizontal, 16)
            }
        }
    }

    // MARK: Explore Our Menu (category tiles)

    private var exploreMenu: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(lead: "Explore", accent: "Our Menu", action: ("View More", { router.tab = .order }))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(pe.orderedCategories) { c in
                        Button {
                            router.menuCategoryId = c.id
                            router.tab = .order
                        } label: {
                            CatalogImageView(path: c.image, mode: .fill)
                                .frame(width: 112, height: 106)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border))
                        }
                        .accessibilityLabel(c.name)
                    }
                }.padding(.horizontal, 16)
            }
        }
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(lead: "Quick", accent: "Actions")
            HStack(spacing: 12) {
                quickAction("Hut Locator", "mappin.and.ellipse") { showStores = true }
                quickAction("My Orders", "bag") { router.tab = .profile }
                quickAction("Inbox", "bell") { InboxManager.shared.present() }
            }.padding(.horizontal, 16)
        }
    }

    private func quickAction(_ title: String, _ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title).font(Theme.body(13, .semibold)).foregroundColor(Theme.ink)
                Spacer(minLength: 2)
                Image(systemName: icon).font(.system(size: 20, weight: .semibold)).foregroundColor(Theme.red)
            }
            .padding(12).frame(height: 58)
            .background(Theme.redTint.opacity(0.35)).clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private var footer: some View {
        VStack(spacing: 6) {
            CatalogImageView(path: Catalog.shared.brand.feedGoodTimes).frame(height: 56)
            Text("Prices include 6% SST. Terms and conditions apply.").font(Theme.body(11)).foregroundColor(Theme.greyLight)
        }
        .padding(.top, 8)
    }
}

/// Deal tile in the "Our Highlights" style: portrait image plus Delivery / Takeaway tags.
struct DealTile: View {
    let deal: Catalog.Deal
    var width: CGFloat = 132
    @EnvironmentObject var router: DeepLinkRouter

    var body: some View {
        Button {
            Analytics.track(.dealViewed, ["Deal ID": deal.id, "Deal Name": deal.name, "Price": deal.price])
            router.product = Catalog.shared.product(deal.id)
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                CatalogImageView(path: deal.image, mode: .fill)
                    .frame(width: width, height: width * 7 / 6)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                HStack(spacing: 4) { Tag(text: "Delivery"); Tag(text: "Takeaway") }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(deal.name)
    }
}

struct OrderModeToggle: View {
    @EnvironmentObject var cart: CartStore
    var body: some View {
        HStack(spacing: 0) {
            ForEach(OrderMode.allCases) { mode in
                Button {
                    guard cart.orderMode != mode else { return }
                    cart.orderMode = mode
                    let store = cart.selectedStore?.name ?? "Not selected"
                    Analytics.track(.orderModeSelected, ["Mode": mode.rawValue, "Store Name": store])
                    Analytics.setProfile([.preferredOrderMode: mode.rawValue])
                } label: {
                    Text(mode.rawValue)
                        .font(Theme.body(15, cart.orderMode == mode ? .bold : .medium))
                        .foregroundColor(cart.orderMode == mode ? Theme.ink : Theme.greyLight)
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .background(cart.orderMode == mode ? Color.white : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 9))
                        .shadow(color: .black.opacity(cart.orderMode == mode ? 0.08 : 0), radius: 3, y: 1)
                }
            }
        }
        .padding(4)
        .background(Color(hex: "#EBEBEB")).clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner
    func path(in rect: CGRect) -> Path {
        Path(UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius)).cgPath)
    }
}
