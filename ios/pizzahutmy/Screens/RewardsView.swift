import SwiftUI

/// "My Rewards": wallet 1460 balances, transaction history and available coupons (Promo APIs).
struct RewardsView: View {
    @EnvironmentObject var session: SessionStore
    @EnvironmentObject var cart: CartStore
    @EnvironmentObject var router: DeepLinkRouter

    @State private var wallet: WalletRecord?
    @State private var transactions: [WalletTransaction] = []
    @State private var coupons: [Coupon] = []
    @State private var loading = false
    @State private var walletError: String?
    @State private var couponError: String?
    @State private var showLogin = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    header
                    if session.isLoggedIn {
                        DisplaySlotView(slot: .rewardsBanner, height: 130) { rewardsFallback }
                        couponsSection
                        historySection
                    } else {
                        EmptyStateCard(icon: "star.circle", title: "Log in to see your rewards",
                                       message: "Earn \(Int(DemoConfig.pointsPerRinggit)) point for every RM 1 you spend and unlock coupons.",
                                       action: ("Log in", { showLogin = true }))
                            .padding(.horizontal, 16)
                        DisplaySlotView(slot: .rewardsBanner, height: 130) { rewardsFallback }
                    }
                }
                .padding(.bottom, 24)
            }
            .background(Theme.surface.ignoresSafeArea())
            .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack)
        .sheet(isPresented: $showLogin) { NavigationView { LoginView(onDone: { showLogin = false }) } }
        .onAppear { load() }
        .onChange(of: session.user) { _ in load() }
    }

    private var header: some View {
        VStack(spacing: 10) {
            Text("My Rewards").font(Theme.heading(26)).foregroundColor(.white)
            if let user = session.user {
                Text("Hi \(user.name.components(separatedBy: " ").first ?? user.name) · \(session.tier) member")
                    .font(Theme.body(14, .medium)).foregroundColor(.white.opacity(0.9))
                if loading && wallet == nil {
                    ProgressView().tint(.white).padding(.vertical, 18)
                } else if let walletError {
                    Text(walletError).font(Theme.body(14)).foregroundColor(.white).multilineTextAlignment(.center).padding(.vertical, 12)
                    Button("Try again") { load() }.font(Theme.body(14, .bold)).foregroundColor(Theme.red)
                        .padding(.horizontal, 18).padding(.vertical, 8).background(Color.white).clipShape(Capsule())
                } else {
                    Text("You currently have").font(Theme.body(13)).foregroundColor(.white.opacity(0.85)).padding(.top, 6)
                    Text("\(format(wallet?.activePoints)) Points")
                        .font(Theme.heading(30)).foregroundColor(.white)
                        .padding(.horizontal, 22).padding(.vertical, 8)
                        .background(Theme.redDeep.opacity(0.45)).clipShape(RoundedRectangle(cornerRadius: 12))
                    HStack(spacing: 10) {
                        stat("Active", wallet?.activePoints)
                        stat("Promised", wallet?.totalPromisedPoints)
                        stat("Expired", wallet?.expiredPoints)
                    }
                    .padding(.top, 4)
                }
            } else {
                Text("Collect points with every order").font(Theme.body(14)).foregroundColor(.white.opacity(0.9))
            }
        }
        .padding(.horizontal, 16).padding(.top, 18).padding(.bottom, 24)
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                Theme.red
                CatalogImageView(path: Catalog.shared.brand.redBackground, mode: .fill).opacity(0.18).blendMode(.multiply)
            }
            .ignoresSafeArea(edges: .top)
        )
    }

    private func stat(_ label: String, _ value: Double?) -> some View {
        VStack(spacing: 2) {
            Text(format(value)).font(Theme.body(17, .bold)).foregroundColor(.white)
            Text(label).font(Theme.body(12)).foregroundColor(.white.opacity(0.85))
        }
        .frame(maxWidth: .infinity).padding(.vertical, 10)
        .background(Color.white.opacity(0.14)).clipShape(RoundedRectangle(cornerRadius: 10))
    }

    /// Fallback for rewards_banner.
    private var rewardsFallback: some View {
        HStack(spacing: 14) {
            CatalogImageView(path: Catalog.shared.icons["rewards"]).frame(width: 56, height: 56)
            VStack(alignment: .leading, spacing: 4) {
                Text("Earn on every order").font(Theme.body(16, .bold)).foregroundColor(Theme.ink)
                Text("\(Int(DemoConfig.pointsPerRinggit)) point for every RM 1 spent, on Delivery and Takeaway.").font(Theme.body(13)).foregroundColor(Theme.grey)
            }
            Spacer()
        }
        .padding(14).background(Color.white).clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.border))
        .padding(.horizontal, 16)
    }

    private var couponsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(lead: "My", accent: "Coupons")
            if let couponError {
                Text(couponError).font(Theme.body(13)).foregroundColor(Theme.grey).padding(.horizontal, 16)
            } else if coupons.isEmpty && !loading {
                Text("No coupons available right now. Check back soon.").font(Theme.body(13)).foregroundColor(Theme.grey).padding(.horizontal, 16)
            }
            ForEach(coupons) { CouponCard(coupon: $0, onApply: apply) }
        }
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(lead: "Points", accent: "History")
            if transactions.isEmpty && !loading && walletError == nil {
                Text("No transactions yet. Place an order to start earning.").font(Theme.body(13)).foregroundColor(Theme.grey).padding(.horizontal, 16)
            }
            VStack(spacing: 0) {
                ForEach(transactions) { t in
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(t.description?.isEmpty == false ? t.description! : (t.type ?? "Transaction").capitalized)
                                .font(Theme.body(14, .medium)).foregroundColor(Theme.ink).lineLimit(2)
                            Text(dateText(t.date) + " · " + (t.type ?? "").capitalized).font(Theme.body(12)).foregroundColor(Theme.grey)
                        }
                        Spacer()
                        Text((t.isCredit ? "+" : "-") + format(t.points)).font(Theme.body(15, .bold))
                            .foregroundColor(t.isCredit ? Theme.success : Theme.red)
                    }
                    .padding(12)
                    if t.id != transactions.last?.id { Divider().padding(.leading, 12) }
                }
            }
            .background(Color.white).clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, 16)
        }
    }

    private func apply(_ coupon: Coupon) {
        cart.pendingCouponCode = coupon.code
        if cart.items.isEmpty {
            router.tab = .order
        } else {
            router.showCart = true
        }
    }

    private func load() {
        guard let identity = session.user?.identity else {
            wallet = nil; transactions = []; coupons = []
            return
        }
        loading = true
        walletError = nil
        couponError = nil
        Task { @MainActor in
            // A new profile can take a few seconds to exist after onUserLogin, so retry briefly
            // and then treat it as a new member with no points yet.
            var attempt = 0
            while true {
                do {
                    wallet = try await PromoAPI.shared.wallet(identity: identity)
                    transactions = try await PromoAPI.shared.transactions(identity: identity).record?.allTransactions ?? []
                    break
                } catch let error as PromoAPI.PromoError where error.isUnknownIdentity {
                    attempt += 1
                    if attempt >= 4 { wallet = nil; transactions = []; break }
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                } catch {
                    walletError = error.localizedDescription
                    break
                }
            }
            do {
                coupons = try await PromoAPI.shared.fetchCoupons(identity: identity, order: nil).filter { $0.isApplicable != false }
            } catch {
                couponError = error.localizedDescription
            }
            loading = false
            Analytics.track(.rewardsViewed, ["Active Points": wallet?.activePoints ?? 0])
        }
    }

    private func format(_ v: Double?) -> String {
        let v = v ?? 0
        return v.rounded() == v ? String(Int(v)) : String(format: "%.1f", v)
    }

    private func dateText(_ d: Date) -> String {
        let f = DateFormatter(); f.dateStyle = .medium; f.timeStyle = .short
        return f.string(from: d)
    }
}

struct CouponCard: View {
    let coupon: Coupon
    let onApply: (Coupon) -> Void

    var body: some View {
        HStack(spacing: 0) {
            VStack {
                Image(systemName: "ticket.fill").font(.system(size: 22)).foregroundColor(.white)
                Text(coupon.rewardLabel.isEmpty ? "DEAL" : coupon.rewardLabel)
                    .font(.system(size: 11, weight: .heavy)).foregroundColor(.white).multilineTextAlignment(.center)
            }
            .frame(width: 92).frame(maxHeight: .infinity).padding(.vertical, 12)
            .background(Theme.red)
            VStack(alignment: .leading, spacing: 4) {
                Text(coupon.title).font(Theme.body(15, .bold)).foregroundColor(Theme.ink)
                if let d = coupon.description, !d.isEmpty { Text(d).font(Theme.body(12)).foregroundColor(Theme.grey).lineLimit(2) }
                Text("Code: \(coupon.code)").font(Theme.body(12, .semibold)).foregroundColor(Theme.text)
                if let e = coupon.expiryText { Text(e).font(Theme.body(11)).foregroundColor(Theme.greyLight) }
            }
            .padding(12)
            Spacer(minLength: 4)
            Button("Apply") { onApply(coupon) }.buttonStyle(OutlineButtonStyle()).padding(.trailing, 12)
                .disabled(coupon.isApplicable == false)
                .opacity(coupon.isApplicable == false ? 0.5 : 1)
        }
        .background(Color.white).clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.border))
        .padding(.horizontal, 16)
    }
}

struct OffersView: View {
    @EnvironmentObject var cart: CartStore
    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        SectionHeader(lead: "Our", accent: "Highlights").padding(.top, 12)
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(Catalog.shared.deals) { DealTile(deal: $0, width: (UIScreen.main.bounds.width - 44) / 2) }
                        }
                        .padding(.horizontal, 16)
                        SectionHeader(lead: "Limited", accent: "Time Offers")
                        ForEach(Catalog.shared.products(in: "limited-time-offers")) { ProductRow(product: $0) }
                    }
                    .padding(.bottom, cart.itemCount > 0 ? 80 : 20)
                }
                CartPill()
            }
            .background(Theme.surface.ignoresSafeArea())
            .navigationTitle("Offers")
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(.stack)
    }
}
