import UIKit
import UserNotifications
import CleverTapSDK
import CleverTapGeofence

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate,
                         CleverTapInAppNotificationDelegate, CleverTapURLDelegate {

    /// CleverTap's dismissAppInbox reads [[application delegate] window]. A SwiftUI app delegate
    /// has no window property, which crashes with an unrecognized selector, so provide one.
    var window: UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        #if DEBUG
        // UI tests start from a clean demo state (app keys only, CleverTap's own storage is untouched).
        if ProcessInfo.processInfo.arguments.contains("-uiTestReset") {
            for key in ["user", "prefs", "totalOrders", "address", "personaId", "categoryViews", "orderMode", "storeId",
                        "onboardingDone", "recoState", "recoDebug"] { UserDefaults.standard.removeObject(forKey: key) }
        }
        #endif
        // iOS quick start: credentials come from Info.plist (CleverTapAccountID, CleverTapToken). No region is set.
        CleverTap.autoIntegrate()
        CleverTap.setDebugLevel(CleverTapLogLevel.debug.rawValue)

        // Delegates are registered before any in-app or deep link can fire.
        CleverTap.sharedInstance()?.setInAppNotificationDelegate(self)
        CleverTap.sharedInstance()?.setUrlDelegate(self)

        // Push: delegate set at launch. Permission itself is requested later through the
        // iOS permission alert after the first add to cart (see PushManager).
        UNUserNotificationCenter.current().delegate = self
        registerRichPushCategory()
        PushManager.shared.start()

        // Geofence starts after the main SDK. Location permission is requested from Store Locator.
        CleverTapGeofence.monitor.start(didFinishLaunchingWithOptions: launchOptions)

        RecoEngine.shared.startSessionIfNeeded()
        ProductExperience.shared.defineAndFetch()
        NativeDisplayManager.shared.start()
        InboxManager.shared.start()
        return true
    }

    /// Rich push category for CTNotificationContent (Rich Push doc).
    private func registerRichPushCategory() {
        let action1 = UNNotificationAction(identifier: "action_1", title: "Back", options: [])
        let action2 = UNNotificationAction(identifier: "action_2", title: "Next", options: [])
        let action3 = UNNotificationAction(identifier: "action_3", title: "View In App", options: [])
        let category = UNNotificationCategory(identifier: "CTNotification", actions: [action1, action2, action3], intentIdentifiers: [], options: [])
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    // MARK: Push handling (Push doc, step 4)

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        NSLog("%@: failed to register for remote notifications: %@", self.description, error.localizedDescription)
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        NSLog("%@: registered for remote notifications: %@", self.description, deviceToken.description)
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        NSLog("%@: did receive notification response: %@", self.description, response.notification.request.content.userInfo)
        completionHandler()
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        NSLog("%@: will present notification: %@", self.description, notification.request.content.userInfo)
        CleverTap.sharedInstance()?.recordNotificationViewedEvent(withData: notification.request.content.userInfo)
        completionHandler([.badge, .sound, .banner, .list])
    }

    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        NSLog("%@: did receive remote notification completionhandler: %@", self.description, userInfo)
        completionHandler(UIBackgroundFetchResult.noData)
    }

    func pushNotificationTapped(withCustomExtras customExtras: [AnyHashable: Any]!) {
        NSLog("pushNotificationTapped: customExtras: %@", customExtras ?? [:])
    }

    // MARK: CleverTapURLDelegate (push, in-app and inbox URLs)

    func shouldHandleCleverTap(_ url: URL?, for channel: CleverTapChannel) -> Bool {
        guard let url else { return true }
        if url.scheme?.lowercased() == "pizzahutmy" {
            DeepLinkRouter.shared.handle(url)
            return false // handled in-app
        }
        return true // let the SDK open web URLs
    }

    // MARK: CleverTapInAppNotificationDelegate

    func shouldShowInAppNotification(withExtras extras: [AnyHashable: Any]!) -> Bool { true }

    func inAppNotificationDidShow(_ notification: [AnyHashable: Any]!) {
        NSLog("In-App Notification displayed: %@", notification ?? [:])
    }

    func inAppNotificationDismissed(withExtras extras: [AnyHashable: Any]!, andActionExtras actionExtras: [AnyHashable: Any]!) {
        NSLog("In-App dismissed extras: %@ action extras: %@", extras ?? [:], actionExtras ?? [:])
    }

    func inAppNotificationButtonTapped(withCustomExtras customExtras: [AnyHashable: Any]!) {
        if let link = customExtras?["deeplink"] as? String, let url = URL(string: link) {
            DeepLinkRouter.shared.handle(url)
        }
    }
}
