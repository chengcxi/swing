import SwiftUI

// MARK: - Golfr Color Palette
// Derived from the Golfr logo: deep forest green + warm cream
// Mixed with Phantom Wallet dark sleekness + Duolingo friendly warmth

struct GolfrColors {
    // Primary greens (from logo)
    static let primaryDark = Color(hex: "0A3D2E")      // Deepest green — nav bars, headers
    static let primary = Color(hex: "0A4A35")           // Core brand green
    static let primaryMedium = Color(hex: "137A52")     // Mid-green for accents
    static let primaryLight = Color(hex: "1A9E6B")      // Bright green for CTAs, active states

    // Cream / warm neutrals (from logo text)
    static let cream = Color(hex: "F5F0E8")             // Warm off-white
    static let creamLight = Color(hex: "FAF8F4")        // Near-white warm bg
    static let gold = Color(hex: "C9A84C")              // Gold accent — badges, highlights

    // Background layers
    static let backgroundPrimary = Color(hex: "FAFAF8") // Main screen bg
    static let backgroundCard = Color.white             // Card surfaces
    static let backgroundElevated = Color(hex: "F3F4F2")// Slightly elevated sections

    // Text
    static let textPrimary = Color(hex: "1A1A1A")       // Headings, body
    static let textSecondary = Color(hex: "6B7280")     // Captions, muted
    static let textOnDark = Color(hex: "F5F0E8")        // Text on green backgrounds
    static let textOnDarkMuted = Color(hex: "B8C7BE")   // Muted text on dark

    // Semantic
    static let success = Color(hex: "22C55E")
    static let warning = Color(hex: "F59E0B")
    static let error = Color(hex: "EF4444")
    static let info = Color(hex: "3B82F6")

    // Gradients
    static let heroGradient = LinearGradient(
        colors: [Color(hex: "0A3D2E"), Color(hex: "0D5A42"), Color(hex: "137A52")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cardGradient = LinearGradient(
        colors: [Color(hex: "0A4A35"), Color(hex: "0D5A42")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let subtleGradient = LinearGradient(
        colors: [Color(hex: "F5F0E8").opacity(0.5), Color.white],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Typography

struct GolfrFonts {
    static func largeTitle() -> Font {
        .system(size: 28, weight: .bold, design: .rounded)
    }

    static func title() -> Font {
        .system(size: 22, weight: .bold, design: .rounded)
    }

    static func title3() -> Font {
        .system(size: 18, weight: .semibold, design: .rounded)
    }

    static func headline() -> Font {
        .system(size: 16, weight: .semibold, design: .rounded)
    }

    static func body() -> Font {
        .system(size: 15, weight: .regular, design: .rounded)
    }

    static func callout() -> Font {
        .system(size: 14, weight: .medium, design: .rounded)
    }

    static func caption() -> Font {
        .system(size: 12, weight: .medium, design: .rounded)
    }

    static func stat() -> Font {
        .system(size: 32, weight: .bold, design: .rounded)
    }
}

// MARK: - Page Title Font (System rounded bold)

extension GolfrFonts {
    static func pageTitle(size: CGFloat = 22) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }
}

// MARK: - View Modifiers

struct GolfrCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .background(GolfrColors.backgroundCard)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
}

struct GolfrDarkCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(GolfrColors.cardGradient)
            )
            .shadow(color: GolfrColors.primary.opacity(0.3), radius: 12, x: 0, y: 6)
    }
}

struct GolfrPillButtonModifier: ViewModifier {
    var isActive: Bool = true

    func body(content: Content) -> some View {
        content
            .font(GolfrFonts.callout())
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isActive ? GolfrColors.primary : GolfrColors.backgroundCard)
            )
            .foregroundColor(isActive ? .white : GolfrColors.textSecondary)
            .overlay(
                Capsule()
                    .stroke(isActive ? Color.clear : GolfrColors.textSecondary.opacity(0.2), lineWidth: 1)
            )
    }
}

struct GolfrChipModifier: ViewModifier {
    var color: Color = GolfrColors.primary

    func body(content: Content) -> some View {
        content
            .font(GolfrFonts.caption())
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(color.opacity(0.12))
            )
    }
}

// MARK: - View Extensions

extension View {
    func golfrCard(cornerRadius: CGFloat = 16) -> some View {
        modifier(GolfrCardModifier(cornerRadius: cornerRadius))
    }

    func golfrDarkCard() -> some View {
        modifier(GolfrDarkCardModifier())
    }

    func golfrPillButton(isActive: Bool = true) -> some View {
        modifier(GolfrPillButtonModifier(isActive: isActive))
    }

    func golfrChip(color: Color = GolfrColors.primary) -> some View {
        modifier(GolfrChipModifier(color: color))
    }
}

// MARK: - Navigation Button (Phantom-wallet-style circular icon buttons)

struct GolfrNavButton: View {
    let icon: String
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(GolfrColors.textPrimary)
                .frame(width: 34, height: 34)
                .background(
                    Circle()
                        .fill(GolfrColors.backgroundElevated)
                )
        }
    }
}

// MARK: - Hex Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
