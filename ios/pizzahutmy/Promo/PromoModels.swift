import Foundation

// Response shapes from the CleverTap Promo API docs (Get Wallet Details, Get Wallet
// Transactions, Debit/Credit Wallet, Fetch / Validate / Redeem Coupon).
// Every field is optional so a missing key never breaks decoding.

struct PromoFailure: Decodable {
    let status: String?
    let error: String?
    let code: Int?
}

struct WalletDetailsResponse: Decodable {
    let status: String?
    let records: [WalletRecord]?
}

struct WalletRecord: Decodable {
    let walletId: Int?
    let activePoints: Double?
    let totalPromisedPoints: Double?
    let expiredPoints: Double?
    let totalCreditedPoints: Double?
    let totalRedeemedPoints: Double?
}

struct WalletTransactionsResponse: Decodable {
    struct Record: Decodable {
        let allTransactions: [WalletTransaction]?
        let pointsExpiring: PointsExpiring?
    }
    struct PointsExpiring: Decodable {
        let earliestExpiryTimestamp: Double?
        let pointsExpiringSoon: Double?
    }
    let status: String?
    let record: Record?
}

struct WalletTransaction: Decodable, Identifiable {
    let tnxId: String?
    let txnTimestamp: Double?
    let type: String?
    let description: String?
    let points: Double?
    let orderId: String?
    var id: String { tnxId ?? "\(txnTimestamp ?? 0)-\(points ?? 0)" }
    var date: Date { Date(timeIntervalSince1970: txnTimestamp ?? 0) }
    var isCredit: Bool { ["CREDIT", "REFUND", "REVERSE"].contains((type ?? "").uppercased()) }
}

struct CreditDebitResponse: Decodable {
    struct Record: Decodable { let activePoints: Double?; let points: Double?; let tnxId: String? }
    let status: String?
    let record: Record?
}

struct CouponResponse: Decodable {
    let status: String?
    let records: [Coupon]?
}

struct Coupon: Decodable, Identifiable {
    struct DiscountEffect: Decodable {
        let discountRate: Double?
        let discountValue: String?
        let discountType: String?
        let rewardType: String?
    }
    struct Savings: Decodable {
        struct Order: Decodable { let orderNetAmount: Double? }
        let orderDiscount: Double?
        let orderCashbackPoints: Double?
        let order: Order?
    }
    let couponCode: String?
    let couponCodeId: Int?
    let couponName: String?
    let description: String?
    let message: String?
    let isApplicable: Bool?
    let couponExpiry: Double?
    let couponExpiryNever: Bool?
    let termsAndConditions: [String]?
    let discountEffect: DiscountEffect?
    let couponSavings: Savings?
    let bestCoupon: String?

    var id: String { "\(couponCodeId ?? 0)-\(couponCode ?? "")" }
    var code: String { couponCode ?? "" }
    var title: String { (couponName?.isEmpty == false ? couponName : nil) ?? code }

    /// Human readable reward, for example "RM 10.00 off" or "20% off".
    var rewardLabel: String {
        guard let e = discountEffect, let rate = e.discountRate else { return "" }
        let isCashback = (e.rewardType ?? "").lowercased() == "cashback"
        let amount = (e.discountValue ?? "").lowercased() == "percentage" ? "\(Int(rate))%" : rate.rm
        return isCashback ? "\(amount) cashback points" : "\(amount) off"
    }

    var expiryText: String? {
        if couponExpiryNever == true { return nil }
        guard let ts = couponExpiry, ts > 0, ts < 4_000_000_000 else { return nil }
        let f = DateFormatter(); f.dateStyle = .medium
        return "Valid until " + f.string(from: Date(timeIntervalSince1970: ts))
    }
}

/// Order payload shared by Fetch, Validate and Redeem Coupon.
struct CouponOrder: Encodable {
    struct Item: Encodable {
        let productId: String
        let itemName: String
        let category: String
        let subCategory: String
        let unitPrice: Double
        let mrp: Double
        let quantity: Int
    }
    let orderId: String
    let saleAmount: Double
    let saleMrpTotal: Double
    let saleChannel: String
    let locationId: String?
    let orderStatus: String?
    let paymentMode: String?
    let cartQuantity: Int
    let items: [Item]
}
