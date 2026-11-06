import Foundation
import CleverTapSDK

/// Native Display slots, routed by the custom key-value `slot` on each display unit.
enum DisplaySlot: String, CaseIterable {
    case homeHero = "home_hero"
    case homeStrip = "home_strip"
    case menuTop = "menu_top"
    case cartUpsell = "cart_upsell"
    case rewardsBanner = "rewards_banner"
}

struct DisplayUnitModel: Identifiable, Equatable {
    let id: String
    let title: String?
    let message: String?
    let titleColor: String?
    let messageColor: String?
    let mediaUrl: URL?
    let actionUrl: URL?
    let bgColor: String?
}

final class NativeDisplayManager: NSObject, ObservableObject, CleverTapDisplayUnitDelegate {
    static let shared = NativeDisplayManager()

    @Published private(set) var units: [DisplaySlot: [DisplayUnitModel]] = [:]
    private var viewedThisSession = Set<String>()

    func start() {
        CleverTap.sharedInstance()?.setDisplayUnitDelegate(self)
        if let cached = CleverTap.sharedInstance()?.getAllDisplayUnits() { update(cached) }
    }

    // MARK: CleverTapDisplayUnitDelegate

    func displayUnitsUpdated(_ displayUnits: [CleverTapDisplayUnit]) {
        update(displayUnits)
    }

    private func update(_ displayUnits: [CleverTapDisplayUnit]) {
        var bySlot: [DisplaySlot: [DisplayUnitModel]] = [:]
        for unit in displayUnits {
            guard let id = unit.unitID,
                  let raw = unit.customExtras?["slot"] as? String,
                  let slot = DisplaySlot(rawValue: raw.trimmingCharacters(in: .whitespaces).lowercased()) else { continue }
            let c = unit.contents?.first
            bySlot[slot, default: []].append(DisplayUnitModel(
                id: id, title: c?.title, message: c?.message, titleColor: c?.titleColor, messageColor: c?.messageColor,
                mediaUrl: c?.mediaUrl.flatMap(URL.init(string:)), actionUrl: c?.actionUrl.flatMap(URL.init(string:)),
                bgColor: unit.bgColor))
        }
        DispatchQueue.main.async { self.units = bySlot }
    }

    func units(for slot: DisplaySlot) -> [DisplayUnitModel] { units[slot] ?? [] }

    func recordViewed(_ unit: DisplayUnitModel) {
        guard !viewedThisSession.contains(unit.id) else { return }
        viewedThisSession.insert(unit.id)
        CleverTap.sharedInstance()?.recordDisplayUnitViewedEvent(forID: unit.id)
    }

    func recordClicked(_ unit: DisplayUnitModel) {
        CleverTap.sharedInstance()?.recordDisplayUnitClickedEvent(forID: unit.id)
    }
}
