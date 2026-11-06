import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            Theme.red.ignoresSafeArea()
            VStack(spacing: 18) {
                CatalogImageView(path: Catalog.shared.brand.logo)
                    .frame(width: 150, height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 28))
                    .shadow(color: .black.opacity(0.2), radius: 12, y: 6)
                ProgressView().tint(.white)
            }
        }
    }
}

struct OnboardingView: View {
    let onDone: () -> Void
    @State private var page = 0

    private let pages: [(image: String, title: String, body: String)] = [
        (Catalog.shared.banners[0].app, "Order for delivery or takeaway", "Pick Delivery or Takeaway, choose your Hut, and we will have it hot and ready."),
        (Catalog.shared.banners[2].app, "Find our best deals", "App-only deals, MyBox combos and limited-time favourites, all in one place."),
        (Catalog.shared.banners[3].app, "Earn rewards on every order", "Log in to collect points on every order and unlock coupons in My Rewards."),
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button("Skip", action: onDone).font(Theme.body(15, .semibold)).foregroundColor(Theme.grey).padding()
            }
            TabView(selection: $page) {
                ForEach(pages.indices, id: \.self) { i in
                    VStack(spacing: 22) {
                        CatalogImageView(path: pages[i].image, mode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .padding(.horizontal, 20)
                        Text(pages[i].title).font(Theme.heading(26)).foregroundColor(Theme.ink).multilineTextAlignment(.center)
                        Text(pages[i].body).font(Theme.body(16)).foregroundColor(Theme.grey).multilineTextAlignment(.center).padding(.horizontal, 28)
                        Spacer()
                    }.tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            Button(page == pages.count - 1 ? "Start ordering" : "Next") {
                if page == pages.count - 1 { onDone() } else { withAnimation { page += 1 } }
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(20)
        }
        .background(Color.white.ignoresSafeArea())
    }
}
