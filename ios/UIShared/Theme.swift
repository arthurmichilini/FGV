import SwiftUI
import UIKit

// Identidade visual: verde-petróleo profundo (tinta de cartão premium) + ouro das milhas.
// Usado pelo app, pelo widget e pela extensão de compartilhamento.

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255,
                  green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255,
                  alpha: 1)
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(uiColor: UIColor(hex: hex))
    }

    static func adaptive(light: UInt32, dark: UInt32) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light)
        })
    }
}

enum Theme {
    static let ink = Color.adaptive(light: 0x0E3B37, dark: 0x17504A)
    static let inkDeep = Color.adaptive(light: 0x062824, dark: 0x0C302B)
    static let onInk = Color(hex: 0xF3EFE3)
    static let gold = Color.adaptive(light: 0xD99A1E, dark: 0xEDB548)
    static let accent = Color.adaptive(light: 0x0E7A6D, dark: 0x43C2AE)
    static let good = Color.adaptive(light: 0x1A7F52, dark: 0x4CC98D)
    static let warn = Color.adaptive(light: 0xA86F00, dark: 0xE9B44C)
    static let bad = Color.adaptive(light: 0xB4372B, dark: 0xF07A6C)
    static let card = Color(uiColor: .secondarySystemGroupedBackground)
    static let background = Color(uiColor: .systemGroupedBackground)

    static var heroGradient: LinearGradient {
        LinearGradient(colors: [ink, inkDeep], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static func scoreColor(_ score: Int) -> Color {
        if score >= 80 { return Color(hex: 0x5FD39B) }
        if score >= 55 { return Color(hex: 0xEDB548) }
        return Color(hex: 0xFF8D7A)
    }

    static func tone(_ tone: VerdictTone) -> Color {
        switch tone {
        case .good: return good
        case .warn: return warn
        case .bad: return bad
        }
    }
}

/// Quadradinho com a sigla e a cor da marca (Nubank, Netflix, Smiles…).
struct LogoTile: View {
    let abbr: String
    let color: UInt32
    var fg: UInt32 = 0xFFFFFF
    var size: CGFloat = 40

    var body: some View {
        Text(abbr)
            .font(.system(size: size * 0.34, weight: .heavy, design: .rounded))
            .foregroundStyle(Color(hex: fg))
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .frame(width: size, height: size)
            .background(Color(hex: color), in: RoundedRectangle(cornerRadius: size * 0.28, style: .continuous))
            .accessibilityHidden(true)
    }
}

enum PillStyle {
    case good, bad, warn, accent, neutral
}

struct Pill: View {
    let text: String
    var style: PillStyle = .neutral

    var body: some View {
        Text(text)
            .font(.caption2.weight(.bold).monospacedDigit())
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .foregroundStyle(color)
            .background(color.opacity(0.14), in: Capsule())
    }

    private var color: Color {
        switch style {
        case .good: return Theme.good
        case .bad: return Theme.bad
        case .warn: return Theme.warn
        case .accent: return Theme.accent
        case .neutral: return Color.secondary
        }
    }
}
