import Foundation
import CleverTapSDK

/// Custom events. Names are always built from DemoConfig.eventPrefix, never typed in full.
enum AppEvent: String {
    case homeViewed = "Home Viewed"
    case orderModeSelected = "Order Mode Selected"
    case storeSelected = "Store Selected"
    case storeLocatorViewed = "Store Locator Viewed"
    case categoryViewed = "Category Viewed"
    case searchPerformed = "Search Performed"
    case dealViewed = "Deal Viewed"
    case productViewed = "Product Viewed"
    case productCustomised = "Product Customised"
    case addedToCart = "Added To Cart"
    case removedFromCart = "Removed From Cart"
    case cartViewed = "Cart Viewed"
    case checkoutStarted = "Checkout Started"
    case couponApplied = "Coupon Applied"
    case orderPlaced = "Order Placed"
    case orderTracked = "Order Tracked"
    case rewardsViewed = "Rewards Viewed"
    case login = "Login"
    case logout = "Logout"
    case pushPermissionResponse = "Push Permission Response"
    case locationPermissionResponse = "Location Permission Response"
    case recommendationViewed = "Recommendation Viewed"
    case recommendationClicked = "Recommendation Clicked"
    case qrScanned = "QR Scanned"
    case registrationCompleted = "Registration Completed"
    case loginScreenViewed = "Login Screen Viewed"

    var name: String { DemoConfig.eventName(rawValue) }
}

/// Custom profile properties. Keys are always built from DemoConfig.eventPrefix.
enum ProfileKey: String {
    case preferredOrderMode = "Preferred Order Mode"
    case preferredStore = "Preferred Store"
    case favouriteCategory = "Favourite Category"
    case loyaltyTier = "Loyalty Tier"
    case totalOrders = "Total Orders"
    case lastOrderValue = "Last Order Value"
    case preferredPayment = "Preferred Payment"
    case signupPlatform = "Signup Platform"
    case lastCouponUsed = "Last Coupon Used"
    case appLanguage = "App Language"
    case topAffinity = "Top Affinity"
    case entrySource = "Entry Source"
    case entryStoreId = "Entry Store ID"

    var key: String { DemoConfig.profileKey(rawValue) }
}

enum Analytics {
    private static var ct: CleverTap? { CleverTap.sharedInstance() }

    /// Records a custom event. Platform and Currency are added to every event.
    static func track(_ event: AppEvent, _ props: [String: Any] = [:]) {
        var all = props
        all["Platform"] = DemoConfig.platform
        all["Currency"] = DemoConfig.currency
        ct?.recordEvent(event.name, withProps: all)
    }

    /// Pushes custom (prefixed) profile properties. Works for anonymous users too.
    static func setProfile(_ values: [ProfileKey: Any], refetchVariables: Bool = true) {
        var dict: [String: Any] = [:]
        for (k, v) in values { dict[k.key] = v }
        ct?.profilePush(dict)
        // Product Experiences segments can depend on these properties, so re-fetch
        // variables right after the update (per the iOS Product Experiences doc).
        if refetchVariables { ProductExperience.shared.fetch() }
    }

    /// Pushes standard CleverTap keys (unprefixed), for example MSG-push.
    static func setStandardProfile(_ values: [String: Any]) {
        ct?.profilePush(values)
    }

    /// Identifies the user. Standard keys stay unprefixed; custom keys use the prefix.
    static func login(standard: [String: Any], custom: [ProfileKey: Any]) {
        var profile = standard
        for (k, v) in custom { profile[k.key] = v }
        ct?.onUserLogin(profile)
        ProductExperience.shared.fetch()
    }
}
