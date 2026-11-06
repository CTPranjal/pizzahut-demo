import Foundation

/// Single source of truth for demo-wide constants on iOS.
/// CleverTap Account ID and Token live in Info.plist, the passcode and Promo API
/// base URL live in Secrets.plist (git-ignored). Nothing else should hardcode these.
enum DemoConfig {
    /// Every custom event name and custom profile key starts with this prefix and a space.
    static let eventPrefix = "PizzaHut"

    /// Loyalty wallet used for "My Rewards". Identify it only by this ID.
    static let loyaltyWalletId = 1460

    /// Country code of the demo user's phone number (stored in E.164; Identity is separate).
    static let phoneCountryCode = "+63"

    static let platform = "iOS"
    static let currency = "MYR"
    static let appLanguage = "English"

    /// Earn rule for wallet 1460: points credited per RM 1 of the amount paid (rounded down).
    static let pointsPerRinggit = 1.0

    /// Demo assumption (not from pizzahut.com.my): flat delivery fee below the free delivery threshold.
    static let deliveryFee = 5.00

    /// Sale channel recorded against wallet and coupon transactions.
    static let saleChannel = "iOS App"

    /// Fixed values for the offline to online (store QR) demo events raised at login.
    static let demoEntrySource = "store_qr"
    static let demoEntryStoreId = "PH-2395730871"

    /// Loyalty tier rule, based on total orders.
    static func loyaltyTier(totalOrders: Int) -> String {
        switch totalOrders {
        case 15...: return "Gold"
        case 5...: return "Silver"
        default: return "Bronze"
        }
    }

    static func eventName(_ suffix: String) -> String { "\(eventPrefix) \(suffix)" }
    static func profileKey(_ suffix: String) -> String { "\(eventPrefix) \(suffix)" }
}
