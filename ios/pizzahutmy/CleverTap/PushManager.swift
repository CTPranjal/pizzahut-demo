import UIKit
import UserNotifications
import CleverTapSDK

/// Push permission is asked after the first meaningful action (first add to cart) with the
/// iOS system alert, using the registration code from the CleverTap iOS push doc.
final class PushManager {
    static let shared = PushManager()

    func start() {
        // If permission was granted earlier, register for remote notifications on every launch.
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if settings.authorizationStatus == .authorized {
                DispatchQueue.main.async { UIApplication.shared.registerForRemoteNotifications() }
            }
        }
    }

    /// Shows the iOS permission alert once, if permission has not been decided yet.
    func askAfterMeaningfulAction() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .notDetermined else { return }
            UNUserNotificationCenter.current().requestAuthorization(options: [.sound, .badge, .alert]) { granted, _ in
                Analytics.track(.pushPermissionResponse, ["Granted": granted])
                if granted {
                    DispatchQueue.main.async { UIApplication.shared.registerForRemoteNotifications() }
                }
            }
        }
    }
}
