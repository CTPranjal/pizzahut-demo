import SwiftUI

/// Renders CleverTap native display units for a slot, recording viewed and clicked.
/// When the slot has no unit, the static brand fallback is shown so the screen never looks empty.
struct DisplaySlotView<Fallback: View>: View {
    let slot: DisplaySlot
    var height: CGFloat = 170
    @ViewBuilder var fallback: () -> Fallback
    @EnvironmentObject var display: NativeDisplayManager
    @EnvironmentObject var router: DeepLinkRouter

    var body: some View {
        let units = display.units(for: slot)
        if units.isEmpty {
            fallback()
        } else if units.count == 1, let unit = units.first {
            card(unit)
        } else {
            TabView {
                ForEach(units) { card($0) }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .frame(height: height + 20)
        }
    }

    private func card(_ unit: DisplayUnitModel) -> some View {
        Button {
            display.recordClicked(unit)
            if let url = unit.actionUrl { router.handle(url) }
        } label: {
            ZStack(alignment: .bottomLeading) {
                Rectangle().fill(unit.bgColor.map { Color(hex: $0) } ?? Theme.red)
                if unit.mediaUrl != nil { RemoteImage(url: unit.mediaUrl, mode: .fill) }
                if unit.title?.isEmpty == false || unit.message?.isEmpty == false {
                    VStack(alignment: .leading, spacing: 4) {
                        if let t = unit.title, !t.isEmpty {
                            Text(t).font(Theme.heading(20)).foregroundColor(unit.titleColor.map { Color(hex: $0) } ?? .white)
                        }
                        if let m = unit.message, !m.isEmpty {
                            Text(m).font(Theme.body(14, .medium)).foregroundColor(unit.messageColor.map { Color(hex: $0) } ?? .white)
                        }
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(unit.mediaUrl == nil ? Color.clear : Color.black.opacity(0.28))
                }
            }
            .frame(height: height)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, 16)
        }
        .buttonStyle(.plain)
        .onAppear { display.recordViewed(unit) }
    }
}

/// Static hero carousel from the real homepage banners (fallback for home_hero).
struct BannerCarousel: View {
    @EnvironmentObject var router: DeepLinkRouter
    @State private var index = 0
    private let timer = Timer.publish(every: 4, on: .main, in: .common).autoconnect()
    let banners = Catalog.shared.banners

    var body: some View {
        TabView(selection: $index) {
            ForEach(Array(banners.enumerated()), id: \.offset) { i, b in
                Button {
                    if let id = b.productId, let p = Catalog.shared.product(id) { router.product = p } else { router.tab = .order }
                } label: {
                    CatalogImageView(path: b.app, mode: .fill)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal, 16)
                }
                .buttonStyle(.plain)
                .tag(i)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .frame(height: (UIScreen.main.bounds.width - 32) * 5 / 9 + 30)
        .onReceive(timer) { _ in withAnimation { index = (index + 1) % max(1, banners.count) } }
    }
}
