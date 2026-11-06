import Foundation
import CleverTapSDK

/// Product Experiences (Remote Config) variables. Defined at launch, synced in DEBUG,
/// fetched on launch, and re-published whenever the SDK reports a change.
final class ProductExperience: ObservableObject {
    static let shared = ProductExperience()

    enum Defaults {
        static let homeHeadline = "Feed Good Times"
        static let homeSubheadline = "Hot pizza, delivered or ready for takeaway."
        static let featuredDealId = "my-box-fanta-combo-myboxfanta"
        static let primaryCtaText = "Order Now"
        static let freeDeliveryThreshold = 60.0
        static let showRewardsTab = true
        static var menuCategoryOrder: String { Catalog.shared.categories.map(\.id).joined(separator: ",") }
        static let recoStrategy = "personalised"
        static let recoPinnedIds = ""
        static let recoRowTitle = "Picked for you"
        static let loginHeadline = "Log in to earn points and use coupons"
        static let loginTeaser = ""
        static let loginCtaPrefix = "Log in as"
    }

    /// Variable names. Every variable is nested under the PizzaHut group on the dashboard
    /// ("PizzaHut.<name>"); the SDK groups variables by the dot in the name.
    enum VarName {
        static func grouped(_ name: String) -> String { "\(DemoConfig.eventPrefix).\(name)" }
        static let homeHeadline = grouped("home_headline")
        static let homeSubheadline = grouped("home_subheadline")
        static let featuredDealId = grouped("featured_deal_id")
        static let primaryCtaText = grouped("primary_cta_text")
        static let freeDeliveryThreshold = grouped("free_delivery_threshold")
        static let showRewardsTab = grouped("show_rewards_tab")
        static let menuCategoryOrder = grouped("menu_category_order")
        static let recoStrategy = grouped("reco_strategy")
        static let recoPinnedIds = grouped("reco_pinned_ids")
        static let recoRowTitle = grouped("reco_row_title")
        static let loginHeadline = grouped("login_headline")
        static let loginTeaser = grouped("login_teaser")
        static let loginCtaPrefix = grouped("login_cta_prefix")
    }

    @Published private(set) var homeHeadline = Defaults.homeHeadline
    @Published private(set) var homeSubheadline = Defaults.homeSubheadline
    @Published private(set) var featuredDealId = Defaults.featuredDealId
    @Published private(set) var primaryCtaText = Defaults.primaryCtaText
    @Published private(set) var freeDeliveryThreshold = Defaults.freeDeliveryThreshold
    @Published private(set) var showRewardsTab = Defaults.showRewardsTab
    @Published private(set) var menuCategoryOrder = Defaults.menuCategoryOrder
    @Published private(set) var recoStrategy = RecoStrategy(variable: Defaults.recoStrategy)
    @Published private(set) var recoPinnedIds = Defaults.recoPinnedIds
    @Published private(set) var recoRowTitle = Defaults.recoRowTitle
    @Published private(set) var loginHeadline = Defaults.loginHeadline
    /// Empty means the teaser is hidden (the control experience).
    @Published private(set) var loginTeaser = Defaults.loginTeaser
    @Published private(set) var loginCtaPrefix = Defaults.loginCtaPrefix

    private var vHeadline: Var?
    private var vSubheadline: Var?
    private var vFeaturedDeal: Var?
    private var vPrimaryCta: Var?
    private var vThreshold: Var?
    private var vShowRewards: Var?
    private var vCategoryOrder: Var?
    private var vRecoStrategy: Var?
    private var vRecoPinned: Var?
    private var vRecoTitle: Var?
    private var vLoginHeadline: Var?
    private var vLoginTeaser: Var?
    private var vLoginCtaPrefix: Var?

    /// Call from application(_:didFinishLaunchingWithOptions:) after CleverTap.autoIntegrate().
    func defineAndFetch() {
        guard let ct = CleverTap.sharedInstance() else { return }
        // 1. Define variables
        vHeadline = ct.defineVar(name: VarName.homeHeadline, string: Defaults.homeHeadline)
        vSubheadline = ct.defineVar(name: VarName.homeSubheadline, string: Defaults.homeSubheadline)
        vFeaturedDeal = ct.defineVar(name: VarName.featuredDealId, string: Defaults.featuredDealId)
        vPrimaryCta = ct.defineVar(name: VarName.primaryCtaText, string: Defaults.primaryCtaText)
        vThreshold = ct.defineVar(name: VarName.freeDeliveryThreshold, number: NSNumber(value: Defaults.freeDeliveryThreshold))
        vShowRewards = ct.defineVar(name: VarName.showRewardsTab, boolean: Defaults.showRewardsTab)
        vCategoryOrder = ct.defineVar(name: VarName.menuCategoryOrder, string: Defaults.menuCategoryOrder)
        vRecoStrategy = ct.defineVar(name: VarName.recoStrategy, string: Defaults.recoStrategy)
        vRecoPinned = ct.defineVar(name: VarName.recoPinnedIds, string: Defaults.recoPinnedIds)
        vRecoTitle = ct.defineVar(name: VarName.recoRowTitle, string: Defaults.recoRowTitle)
        vLoginHeadline = ct.defineVar(name: VarName.loginHeadline, string: Defaults.loginHeadline)
        vLoginTeaser = ct.defineVar(name: VarName.loginTeaser, string: Defaults.loginTeaser)
        vLoginCtaPrefix = ct.defineVar(name: VarName.loginCtaPrefix, string: Defaults.loginCtaPrefix)

        // 2. Add variables changed callback
        ct.onVariablesChanged { [weak self] in self?.apply() }

        // 3. Sync variables from DEBUG builds (requires a test profile on the dashboard)
        #if DEBUG
        ct.syncVariables()
        #endif

        // Fetch on launch
        fetch()
    }

    func fetch() {
        CleverTap.sharedInstance()?.fetchVariables { [weak self] success in
            #if DEBUG
            NSLog("[PE] fetchVariables success=%d", success ? 1 : 0)
            #endif
            self?.apply()
        }
    }

    private func apply() {
        DispatchQueue.main.async { [self] in
            homeHeadline = nonEmpty(vHeadline?.stringValue) ?? Defaults.homeHeadline
            homeSubheadline = nonEmpty(vSubheadline?.stringValue) ?? Defaults.homeSubheadline
            featuredDealId = nonEmpty(vFeaturedDeal?.stringValue) ?? Defaults.featuredDealId
            primaryCtaText = nonEmpty(vPrimaryCta?.stringValue) ?? Defaults.primaryCtaText
            freeDeliveryThreshold = vThreshold?.numberValue?.doubleValue ?? Defaults.freeDeliveryThreshold
            showRewardsTab = vShowRewards?.numberValue?.boolValue ?? Defaults.showRewardsTab
            menuCategoryOrder = nonEmpty(vCategoryOrder?.stringValue) ?? Defaults.menuCategoryOrder
            recoStrategy = RecoStrategy(variable: nonEmpty(vRecoStrategy?.stringValue) ?? Defaults.recoStrategy)
            recoPinnedIds = vRecoPinned?.stringValue ?? Defaults.recoPinnedIds
            recoRowTitle = nonEmpty(vRecoTitle?.stringValue) ?? Defaults.recoRowTitle
            loginHeadline = nonEmpty(vLoginHeadline?.stringValue) ?? Defaults.loginHeadline
            loginTeaser = vLoginTeaser?.stringValue ?? Defaults.loginTeaser
            loginCtaPrefix = nonEmpty(vLoginCtaPrefix?.stringValue) ?? Defaults.loginCtaPrefix
        }
    }

    private func nonEmpty(_ s: String?) -> String? {
        guard let s, !s.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }
        return s
    }

    /// Categories in the order set by menu_category_order. Unknown IDs are ignored and
    /// categories missing from the list are appended in their default order.
    var orderedCategories: [Catalog.Category] {
        let ids = menuCategoryOrder.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
        let all = Catalog.shared.categories
        var result = ids.compactMap { id in all.first { $0.id == id || $0.name.lowercased() == id } }
        result += all.filter { c in !result.contains(c) }
        return result
    }
}
