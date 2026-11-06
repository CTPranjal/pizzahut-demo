import SwiftUI
import CleverTapSDK

enum AppTab: Hashable { case home, rewards, order, offers, profile }

/// Routes pizzahutmy:// deep links from push, in-app, inbox and native display CTAs.
///   pizzahutmy://home  pizzahutmy://menu  pizzahutmy://menu/<categoryId>
///   pizzahutmy://product/<productId>  pizzahutmy://deals  pizzahutmy://rewards
///   pizzahutmy://cart  pizzahutmy://stores  pizzahutmy://account  pizzahutmy://inbox
final class DeepLinkRouter: ObservableObject {
    static let shared = DeepLinkRouter()

    @Published var tab: AppTab = .home
    @Published var product: Product? {
        didSet { productRecoSlot = pendingRecoSlot; pendingRecoSlot = nil }
    }
    /// Set when the product sheet was opened from a recommendation row.
    private(set) var productRecoSlot: RecoSlot?
    private var pendingRecoSlot: RecoSlot?
    @Published var showCart = false
    @Published var showStores = false
    @Published var menuCategoryId: String?

    func openProduct(_ p: Product, fromRecommendation slot: RecoSlot?) {
        pendingRecoSlot = slot
        product = p
    }

    func handle(_ url: URL) {
        guard url.scheme?.lowercased() == "pizzahutmy" else {
            if ["http", "https"].contains(url.scheme?.lowercased() ?? "") { UIApplication.shared.open(url) }
            return
        }
        // Close the inbox before navigating (App Inbox doc, custom handling deeplink).
        CleverTap.sharedInstance()?.dismissAppInbox()
        let host = url.host?.lowercased() ?? ""
        let arg = url.pathComponents.dropFirst().first
        DispatchQueue.main.async { [self] in
            product = nil
            showCart = false
            showStores = false
            switch host {
            case "product":
                tab = .order
                if let arg, let p = Catalog.shared.product(arg) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { self.product = p }
                }
            case "menu":
                tab = .order
                menuCategoryId = arg
            case "deals", "offers": tab = .offers
            case "rewards": tab = .rewards
            case "cart": DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { self.showCart = true }
            case "stores": DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { self.showStores = true }
            case "account", "profile": tab = .profile
            case "inbox": DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { InboxManager.shared.present() }
            default: tab = .home
            }
        }
    }
}
