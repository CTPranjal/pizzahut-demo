import Foundation

/// Reads Secrets.plist (git-ignored). DEMO ONLY: a passcode inside an app binary
/// is not safe for production; a real app would call its own backend instead.
struct Secrets {
    let passcode: String
    let promoApiBase: String
    let accountId: String

    static let shared = Secrets()

    private init() {
        var dict: [String: Any] = [:]
        if let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
           let data = try? Data(contentsOf: url),
           let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] {
            dict = plist
        }
        passcode = dict["CLEVERTAP_PASSCODE"] as? String ?? ""
        promoApiBase = dict["PROMO_API_BASE"] as? String ?? ""
        accountId = Bundle.main.object(forInfoDictionaryKey: "CleverTapAccountID") as? String ?? ""
    }

    var isConfigured: Bool { !passcode.isEmpty && !promoApiBase.isEmpty && !accountId.isEmpty }
}
