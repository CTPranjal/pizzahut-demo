import SwiftUI

/// Brand tokens taken from pizzahut.com.my (see docs/GAPS.md for the font fallback).
enum Theme {
    static let redHex = "#CE2828"
    static let redDarkHex = "#AE2222"
    static let inkHex = "#171717"
    static let greyHex = "#5C5C5C"
    static let surfaceHex = "#F7F7F7"

    static let red = Color(hex: redHex)
    static let redDark = Color(hex: redDarkHex)
    static let redDeep = Color(hex: "#661414")
    static let redTint = Color(hex: "#FFD4D4")
    static let ink = Color(hex: inkHex)
    static let text = Color(hex: "#26201A")
    static let grey = Color(hex: greyHex)
    static let greyLight = Color(hex: "#A3A3A3")
    static let border = Color(hex: "#EBEBEB")
    static let surface = Color(hex: surfaceHex)
    static let success = Color(hex: "#135610")
    static let successBg = Color(hex: "#E9F7E9")

    static func heading(_ size: CGFloat) -> Font { .system(size: size, weight: .heavy) }
    static func body(_ size: CGFloat = 15, _ weight: Font.Weight = .regular) -> Font { .system(size: size, weight: weight) }
}

extension Color {
    init(hex: String) {
        var v: UInt64 = 0
        Scanner(string: hex.replacingOccurrences(of: "#", with: "")).scanHexInt64(&v)
        self.init(red: Double((v >> 16) & 0xFF) / 255, green: Double((v >> 8) & 0xFF) / 255, blue: Double(v & 0xFF) / 255)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    var enabled = true
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.body(16, .bold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(enabled ? (configuration.isPressed ? Theme.redDark : Theme.red) : Theme.greyLight)
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct OutlineButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.body(14, .semibold))
            .foregroundColor(Theme.red)
            .padding(.horizontal, 16).padding(.vertical, 8)
            .background(configuration.isPressed ? Theme.redTint : Color.white)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.red, lineWidth: 1.2))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

/// Section title in the site's "Our **Highlights**" style: first word ink, rest red, with a rule.
struct SectionHeader: View {
    let lead: String
    let accent: String
    var action: (String, () -> Void)?

    var body: some View {
        HStack(spacing: 8) {
            (Text(lead + " ").foregroundColor(Theme.ink) + Text(accent).foregroundColor(Theme.red))
                .font(Theme.body(18, .bold))
            Rectangle().fill(Theme.red.opacity(0.35)).frame(height: 1)
            if let action {
                Button(action: action.1) {
                    HStack(spacing: 2) { Text(action.0); Image(systemName: "chevron.right") }
                        .font(Theme.body(12, .semibold)).foregroundColor(Theme.grey)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.border))
                }
            }
        }
        .padding(.horizontal, 16)
    }
}

struct Tag: View {
    let text: String
    var body: some View {
        Text(text).font(Theme.body(11, .medium)).foregroundColor(Theme.grey)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(Theme.surface).clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

/// Image from the asset catalog, by catalog path.
struct CatalogImageView: View {
    let path: String?
    var mode: ContentMode = .fit
    var body: some View {
        Image(CatalogImage.assetName(for: path)).resizable().aspectRatio(contentMode: mode)
    }
}

/// Remote image with a neutral placeholder (used for CleverTap native display media).
struct RemoteImage: View {
    let url: URL?
    var mode: ContentMode = .fill
    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case let .success(image): image.resizable().aspectRatio(contentMode: mode)
            default: Rectangle().fill(Theme.surface).overlay(ProgressView().opacity(url == nil ? 0 : 1))
            }
        }
    }
}

struct Badge: View {
    let count: Int
    var body: some View {
        if count > 0 {
            Text(count > 99 ? "99+" : "\(count)")
                .font(.system(size: 10, weight: .bold)).foregroundColor(Theme.red)
                .padding(.horizontal, 5).frame(minWidth: 16, minHeight: 16)
                .background(Color.white).clipShape(Capsule())
                .overlay(Capsule().stroke(Theme.red, lineWidth: 1))
        }
    }
}

struct EmptyStateCard: View {
    let icon: String
    let title: String
    let message: String
    var action: (String, () -> Void)?
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon).font(.system(size: 34)).foregroundColor(Theme.red)
            Text(title).font(Theme.body(17, .bold)).foregroundColor(Theme.ink)
            Text(message).font(Theme.body(14)).foregroundColor(Theme.grey).multilineTextAlignment(.center)
            if let action { Button(action.0, action: action.1).buttonStyle(PrimaryButtonStyle()).padding(.top, 6) }
        }
        .padding(20).frame(maxWidth: .infinity)
        .background(Color.white).clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.border))
    }
}
