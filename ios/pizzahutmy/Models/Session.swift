import Foundation

struct UserProfile: Codable, Equatable {
    /// CleverTap Identity, kept separate from Phone (for example PH001).
    var identity: String
    var name: String
    var email: String
    /// E.164, for example +639171234567.
    var phone: String
}

struct NotificationPreferences: Codable, Equatable {
    var push = true
    var email = true
    var sms = true
    var whatsapp = true
}

struct Persona: Identifiable {
    let id: String
    let title: String
    let summary: String
    let profile: UserProfile
    let orderMode: OrderMode
    let favouriteCategoryId: String
    let tier: String
    let totalOrders: Int
    let lastOrderValue: Double
    let preferredPayment: String
    let lastCouponUsed: String
    let storeId: String
    let address: String
    /// Preloaded recommendation history, so Home differs immediately after login.
    let warmStart: RecoEngine.WarmStart

    /// The single master demo profile (long press the logo to log in as it).
    static let all: [Persona] = [
        Persona(id: "master", title: "Master demo profile",
                summary: "Delivery, Pizzas, Gold, high order value",
                profile: UserProfile(identity: "PH001", name: "Aisyah Rahman", email: "aisyah.rahman@pizzahut.com", phone: "+639178420101"),
                orderMode: .delivery, favouriteCategoryId: "pizza", tier: "Gold", totalOrders: 24,
                lastOrderValue: 149.00, preferredPayment: "Credit / Debit Card", lastCouponUsed: "",
                storeId: "PH-2395730871", address: "12, Jalan Telawi 3, Bangsar Baru, 59100 Kuala Lumpur",
                warmStart: .familyFeaster),
    ]
}

final class SessionStore: ObservableObject {
    @Published private(set) var user: UserProfile?
    @Published var preferences: NotificationPreferences { didSet { save() } }
    @Published private(set) var totalOrders: Int
    @Published var deliveryAddress: String { didSet { save() } }
    @Published private(set) var personaId: String?
    private var categoryViews: [String: Int]

    private let defaults = UserDefaults.standard

    init() {
        user = defaults.data(forKey: "user").flatMap { try? JSONDecoder().decode(UserProfile.self, from: $0) }
        preferences = defaults.data(forKey: "prefs").flatMap { try? JSONDecoder().decode(NotificationPreferences.self, from: $0) } ?? NotificationPreferences()
        totalOrders = defaults.integer(forKey: "totalOrders")
        deliveryAddress = defaults.string(forKey: "address") ?? ""
        personaId = defaults.string(forKey: "personaId")
        categoryViews = defaults.dictionary(forKey: "categoryViews") as? [String: Int] ?? [:]
    }

    var isLoggedIn: Bool { user != nil }
    var tier: String { DemoConfig.loyaltyTier(totalOrders: totalOrders) }

    // MARK: Login (single demo user)

    func login(persona: Persona, cart: CartStore) {
        persist(persona.profile)
        personaId = persona.id
        defaults.set(persona.id, forKey: "personaId")
        totalOrders = persona.totalOrders
        defaults.set(totalOrders, forKey: "totalOrders")
        deliveryAddress = persona.address
        categoryViews = [persona.favouriteCategoryId: 100]
        defaults.set(categoryViews, forKey: "categoryViews")
        cart.orderMode = persona.orderMode
        cart.selectedStore = Catalog.shared.store(persona.storeId)
        RecoEngine.shared.warmStart(persona.warmStart)

        var custom: [ProfileKey: Any] = [
            .preferredOrderMode: persona.orderMode.rawValue,
            .preferredStore: cart.selectedStore?.name ?? "",
            .favouriteCategory: Catalog.shared.category(persona.favouriteCategoryId)?.name ?? "",
            .loyaltyTier: persona.tier,
            .totalOrders: persona.totalOrders,
            .lastOrderValue: persona.lastOrderValue,
            .preferredPayment: persona.preferredPayment,
            .signupPlatform: DemoConfig.platform,
            .appLanguage: DemoConfig.appLanguage,
        ]
        if !persona.lastCouponUsed.isEmpty { custom[.lastCouponUsed] = persona.lastCouponUsed }
        Analytics.login(standard: standardKeys(persona.profile), custom: custom)
        Analytics.track(.login, ["Method": "Demo Persona"])
        // The demo login stands in for registration after a store QR scan (UC1, Offline to Online).
        let entry: [String: Any] = ["Entry Source": DemoConfig.demoEntrySource, "Store ID": DemoConfig.demoEntryStoreId]
        Analytics.setProfile([.entrySource: DemoConfig.demoEntrySource, .entryStoreId: DemoConfig.demoEntryStoreId])
        Analytics.track(.qrScanned, entry)
        Analytics.track(.registrationCompleted, entry)
    }

    func logout() {
        Analytics.track(.logout)
        RecoEngine.shared.reset()
        user = nil
        personaId = nil
        totalOrders = 0
        deliveryAddress = ""
        categoryViews = [:]
        for key in ["user", "personaId", "totalOrders", "address", "categoryViews"] { defaults.removeObject(forKey: key) }
    }

    private func persist(_ profile: UserProfile) {
        user = profile
        defaults.set(try? JSONEncoder().encode(profile), forKey: "user")
    }

    /// Standard CleverTap keys, unprefixed, for identity and channel reachability.
    private func standardKeys(_ profile: UserProfile) -> [String: Any] {
        [
            "Identity": profile.identity,
            "Name": profile.name,
            "Email": profile.email,
            "Phone": profile.phone,
            "MSG-push": preferences.push,
            "MSG-email": preferences.email,
            "MSG-sms": preferences.sms,
            "MSG-whatsapp": preferences.whatsapp,
        ]
    }

    func pushPreferences() {
        Analytics.setStandardProfile([
            "MSG-push": preferences.push,
            "MSG-email": preferences.email,
            "MSG-sms": preferences.sms,
            "MSG-whatsapp": preferences.whatsapp,
        ])
    }

    // MARK: Behaviour

    /// Counts category views and pushes the most viewed one as the favourite category when it changes.
    func noteCategoryView(_ categoryId: String) {
        let before = favouriteCategoryId
        categoryViews[categoryId, default: 0] += 1
        defaults.set(categoryViews, forKey: "categoryViews")
        if let after = favouriteCategoryId, after != before, let name = Catalog.shared.category(after)?.name {
            Analytics.setProfile([.favouriteCategory: name])
        }
    }

    var favouriteCategoryId: String? { categoryViews.max { $0.value < $1.value }?.key }

    func recordOrder(value: Double, payment: String, coupon: String?) {
        totalOrders += 1
        defaults.set(totalOrders, forKey: "totalOrders")
        var values: [ProfileKey: Any] = [
            .totalOrders: totalOrders,
            .lastOrderValue: value,
            .preferredPayment: payment,
            .loyaltyTier: tier,
        ]
        if let coupon, !coupon.isEmpty { values[.lastCouponUsed] = coupon }
        Analytics.setProfile(values)
    }

    private func save() {
        defaults.set(try? JSONEncoder().encode(preferences), forKey: "prefs")
        defaults.set(deliveryAddress, forKey: "address")
    }
}
