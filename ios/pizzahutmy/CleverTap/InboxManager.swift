import UIKit
import CleverTapSDK

/// App Inbox: initialised at launch, unread count drives the bell badge.
final class InboxManager: NSObject, ObservableObject, CleverTapInboxViewControllerDelegate {
    static let shared = InboxManager()
    @Published private(set) var unreadCount = 0
    @Published private(set) var isReady = false

    func start() {
        CleverTap.sharedInstance()?.initializeInbox(callback: { [weak self] success in
            DispatchQueue.main.async { self?.isReady = success }
            self?.refresh()
        })
        CleverTap.sharedInstance()?.registerInboxUpdatedBlock { [weak self] in self?.refresh() }
    }

    private func refresh() {
        let count = Int(CleverTap.sharedInstance()?.getInboxMessageUnreadCount() ?? 0)
        DispatchQueue.main.async { self.unreadCount = count }
    }

    /// Presents the CleverTap inbox controller, styled with brand colours.
    func present() {
        let style = CleverTapInboxStyleConfig()
        style.title = "Notifications"
        style.backgroundColor = UIColor(Theme.surfaceHex)
        style.messageTags = ["Offers", "Orders"]
        style.firstTabTitle = "All"
        style.navigationBarTintColor = UIColor(Theme.redHex)
        style.navigationTintColor = .white
        style.tabSelectedBgColor = UIColor(Theme.redHex)
        style.tabSelectedTextColor = UIColor(Theme.redHex)
        style.tabUnSelectedTextColor = UIColor(Theme.greyHex)
        style.noMessageViewText = "No messages yet. Check back for offers and order updates."
        style.noMessageViewTextColor = UIColor(Theme.greyHex)

        guard let inbox = CleverTap.sharedInstance()?.newInboxViewController(with: style, andDelegate: self),
              let top = UIApplication.topViewController() else { return }
        let nav = UINavigationController(rootViewController: inbox)
        nav.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
        top.present(nav, animated: true)
    }

    // MARK: CleverTapInboxViewControllerDelegate

    func messageDidSelect(_ message: CleverTapInboxMessage, at index: Int32, withButtonIndex buttonIndex: Int32) {
        #if DEBUG
        print("[Inbox] message selected id=\(message.messageId ?? "") index=\(index) button=\(buttonIndex)")
        #endif
    }

    func messageButtonTapped(withCustomExtras customExtras: [AnyHashable: Any]?) {
        if let link = customExtras?["deeplink"] as? String, let url = URL(string: link) {
            CleverTap.sharedInstance()?.dismissAppInbox()
            DeepLinkRouter.shared.handle(url)
        }
    }
}

extension UIApplication {
    static func topViewController(base: UIViewController? = nil) -> UIViewController? {
        let root = base ?? UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.windows.first { $0.isKeyWindow } }
            .first?.rootViewController
        if let nav = root as? UINavigationController { return topViewController(base: nav.visibleViewController) }
        if let tab = root as? UITabBarController { return topViewController(base: tab.selectedViewController) }
        if let presented = root?.presentedViewController { return topViewController(base: presented) }
        return root
    }
}

extension UIColor {
    convenience init(_ hex: String) {
        var v: UInt64 = 0
        Scanner(string: hex.replacingOccurrences(of: "#", with: "")).scanHexInt64(&v)
        self.init(red: CGFloat((v >> 16) & 0xFF) / 255, green: CGFloat((v >> 8) & 0xFF) / 255, blue: CGFloat(v & 0xFF) / 255, alpha: 1)
    }
}
