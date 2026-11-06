import Foundation

/// Calls the CleverTap Promo APIs directly from the app.
/// DEMO ONLY: authenticates with X-CleverTap-Account-Id and X-CleverTap-Passcode read from
/// Info.plist and Secrets.plist. A production app must route these calls through its own backend.
final class PromoAPI {
    static let shared = PromoAPI()

    enum PromoError: LocalizedError {
        case notConfigured
        case notLoggedIn
        case api(code: Int?, message: String)
        case network

        /// The profile is not in CleverTap yet (for example, seconds after the first login).
        var isUnknownIdentity: Bool {
            if case let .api(code, message) = self { return code == 400 && message.lowercased().contains("invalid identity") }
            return false
        }

        /// Friendly copy for the UI. Raw JSON is never shown.
        var errorDescription: String? {
            switch self {
            case .notConfigured: return "Rewards are not available right now."
            case .notLoggedIn: return "Log in to use rewards and coupons."
            case .network: return "We could not reach the server. Check your connection and try again."
            case let .api(code, message): return PromoAPI.friendly(code: code, message: message)
            }
        }
    }

    private let session: URLSession = {
        let c = URLSessionConfiguration.default
        c.timeoutIntervalForRequest = 20
        return URLSession(configuration: c)
    }()
    private let secrets = Secrets.shared

    // MARK: Wallet

    /// Get Wallet Details, filtered to the record where walletId == 1460.
    func wallet(identity: String) async throws -> WalletRecord? {
        let res: WalletDetailsResponse = try await request("GET", "/wallets", query: ["identity": identity])
        return res.records?.first { $0.walletId == DemoConfig.loyaltyWalletId }
    }

    func transactions(identity: String) async throws -> WalletTransactionsResponse {
        try await request("GET", "/transactions", query: ["identity": identity, "walletId": "\(DemoConfig.loyaltyWalletId)"])
    }

    /// Credit/Debit Wallet. Points must be positive.
    func credit(identity: String, points: Double, orderId: String, saleAmount: Double, locationId: String?) async throws -> CreditDebitResponse {
        var body: [String: Any] = [
            "description": "Points earned on order \(orderId)",
            "points": points,
            "transactionType": "CREDIT",
            "bucketType": "ACTIVE",
            "orderId": orderId,
            "saleChannel": DemoConfig.saleChannel,
            "saleAmount": saleAmount,
        ]
        if let locationId { body["locationId"] = locationId }
        return try await request("POST", "/creditDebit",
                                 query: ["identity": identity, "walletId": "\(DemoConfig.loyaltyWalletId)"],
                                 json: body)
    }

    // MARK: Coupons

    func fetchCoupons(identity: String?, order: CouponOrder?) async throws -> [Coupon] {
        var q: [String: String] = [:]
        if let identity { q["identity"] = identity }
        var body: [String: Any] = [:]
        if let order { body["order"] = try jsonObject(order) }
        let res: CouponResponse = try await request("POST", "/coupons", query: q, json: body)
        return res.records ?? []
    }

    func validate(code: String, identity: String?, order: CouponOrder) async throws -> Coupon {
        var q: [String: String] = [:]
        if let identity { q["identity"] = identity }
        let res: CouponResponse = try await request("POST", "/coupons/validate", query: q,
                                                    json: ["couponCode": code, "order": try jsonObject(order)])
        guard let coupon = res.records?.first else { throw PromoError.api(code: nil, message: "Coupon code or ID is invalid") }
        return coupon
    }

    func redeem(code: String, identity: String, order: CouponOrder) async throws -> Coupon? {
        let res: CouponResponse = try await request("POST", "/coupons/apply", query: ["identity": identity, "type": "redeem"],
                                                    json: ["couponCode": code, "order": try jsonObject(order)])
        return res.records?.first
    }

    // MARK: Plumbing

    private func jsonObject<T: Encodable>(_ value: T) throws -> Any {
        try JSONSerialization.jsonObject(with: JSONEncoder().encode(value))
    }

    private func request<T: Decodable>(_ method: String, _ path: String, query: [String: String], json: [String: Any]? = nil) async throws -> T {
        guard secrets.isConfigured, var comps = URLComponents(string: secrets.promoApiBase + path) else { throw PromoError.notConfigured }
        comps.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        // "+" in an E.164 identity must be percent-encoded or the server reads it as a space.
        comps.percentEncodedQuery = comps.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
        guard let url = comps.url else { throw PromoError.notConfigured }

        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue(secrets.accountId, forHTTPHeaderField: "X-CleverTap-Account-Id")
        req.setValue(secrets.passcode, forHTTPHeaderField: "X-CleverTap-Passcode")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let json { req.httpBody = try JSONSerialization.data(withJSONObject: json) }

        let data: Data
        let response: URLResponse
        do { (data, response) = try await session.data(for: req) } catch { throw PromoError.network }

        let http = response as? HTTPURLResponse
        #if DEBUG
        NSLog("[PromoAPI] %@ %@ -> %ld %@", method, path, http?.statusCode ?? -1, String(data: data.prefix(300), encoding: .utf8) ?? "")
        #endif
        let failure = try? JSONDecoder().decode(PromoFailure.self, from: data)
        if (http?.statusCode ?? 500) >= 300 || failure?.status?.lowercased() == "fail" {
            throw PromoError.api(code: failure?.code ?? http?.statusCode, message: failure?.error ?? "")
        }
        do { return try JSONDecoder().decode(T.self, from: data) } catch {
            throw PromoError.api(code: nil, message: "")
        }
    }

    /// Maps documented Promo API errors (HTTP 400/401/500/503 and code 777 cases) to friendly copy.
    static func friendly(code: Int?, message: String) -> String {
        let m = message.lowercased()
        if m.contains("expired") { return "This coupon has expired." }
        if m.contains("per-user") || m.contains("per user") || m.contains("user redemption") { return "You have already used this coupon the maximum number of times." }
        if m.contains("redemption limit") || m.contains("redemption exceeded") { return "This coupon has reached its redemption limit." }
        if m.contains("not valid today") || m.contains("specific days") || m.contains("at this time") { return "This coupon is not available right now." }
        if m.contains("log in") || m.contains("login") || m.contains("sign up") { return "Log in to use this coupon." }
        if m.contains("cart validation") || m.contains("product validation") || m.contains("selected items") || m.contains("no product property") {
            return "Your cart does not meet this coupon's conditions yet."
        }
        if m.contains("user property") { return "This coupon is not available for your account." }
        if m.contains("invalid") && m.contains("coupon") { return "We could not find that coupon code." }
        if m.contains("duplicate") && m.contains("orderid") { return "This order has already been processed." }
        if m.contains("exceed") && m.contains("points") { return "You do not have enough points for this." }
        if m.contains("invalid identity") { return "We could not find your rewards account yet." }
        switch code {
        case 401: return "Rewards are not available right now."
        case 503, 500: return "Rewards are busy right now. Please try again in a moment."
        default: return "Something went wrong. Please try again."
        }
    }
}

extension CartStore {
    /// Builds the coupon API order payload from the cart.
    func couponOrder(orderId: String, status: String?, payment: String?) -> CouponOrder {
        CouponOrder(
            orderId: orderId,
            saleAmount: subtotal,
            saleMrpTotal: subtotal,
            saleChannel: DemoConfig.saleChannel,
            locationId: selectedStore?.id,
            orderStatus: status,
            paymentMode: payment,
            cartQuantity: itemCount,
            items: items.map {
                .init(productId: $0.product.id, itemName: $0.product.name, category: $0.product.categoryName,
                      subCategory: $0.product.subcategory, unitPrice: $0.unitPrice, mrp: $0.unitPrice, quantity: $0.quantity)
            })
    }
}
