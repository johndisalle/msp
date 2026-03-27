import SwiftUI

// MARK: - Abide Journey Theme
/// Warm, organic design system — gender-neutral, spiritually grounded.
/// Palette adapts between light and dark mode.
struct AJTheme {
    // MARK: - Primary Colors (same in both modes — used for accents/buttons)
    static let sage = Color(red: 0.43, green: 0.56, blue: 0.52)             // #6E8E85
    static let sageDark = Color(red: 0.31, green: 0.43, blue: 0.40)         // #4E6E65
    static let sageLight = Color(red: 0.56, green: 0.68, blue: 0.63)        // #8FADA1
    static let gold = Color(red: 0.77, green: 0.64, blue: 0.31)             // #C4A24E
    static let goldLight = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.45, green: 0.38, blue: 0.22, alpha: 1)         // muted gold for dark
            : UIColor(red: 0.89, green: 0.83, blue: 0.66, alpha: 1)         // #E2D4A8
    })
    static let sandstone = Color(red: 0.76, green: 0.68, blue: 0.58)        // #C2AD94

    // MARK: - Adaptive Surface Colors
    static let cream = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.11, green: 0.11, blue: 0.13, alpha: 1)         // dark surface
            : UIColor(red: 0.96, green: 0.94, blue: 0.90, alpha: 1)         // #F5F0E6
    })

    static let softWhite = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.14, green: 0.14, blue: 0.16, alpha: 1)         // elevated dark surface
            : UIColor(red: 0.99, green: 0.98, blue: 0.96, alpha: 1)         // #FDFAF4
    })

    static let charcoal = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.93, green: 0.93, blue: 0.94, alpha: 1)         // light text on dark
            : UIColor(red: 0.17, green: 0.19, blue: 0.25, alpha: 1)         // #2B3040
    })

    // MARK: - Semantic Colors
    static let primaryText = charcoal
    static let secondaryText = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.62, green: 0.64, blue: 0.68, alpha: 1)         // lighter secondary for dark
            : UIColor(red: 0.44, green: 0.47, blue: 0.53, alpha: 1)         // #717887
    })
    static let background = cream
    static let cardBackground = softWhite
    static let accent = sage
    static let accentSecondary = gold
    static let accentTertiary = sandstone
    static let destructive = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.90, green: 0.45, blue: 0.45, alpha: 1)         // brighter red for dark
            : UIColor(red: 0.78, green: 0.38, blue: 0.38, alpha: 1)         // #C76161
    })

    // Status colors
    static let success = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.50, green: 0.75, blue: 0.56, alpha: 1)         // brighter green for dark
            : UIColor(red: 0.42, green: 0.63, blue: 0.48, alpha: 1)         // #6BA17A
    })
    static let warning = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.90, green: 0.76, blue: 0.40, alpha: 1)         // brighter gold for dark
            : UIColor(red: 0.82, green: 0.68, blue: 0.35, alpha: 1)         // #D1AD59
    })

    // MARK: - Gradients
    static let morningGradient = LinearGradient(
        colors: [goldLight.opacity(0.5), cream, softWhite],
        startPoint: .top,
        endPoint: .bottom
    )

    static let screenGradient = LinearGradient(
        colors: [cream, softWhite.opacity(0.6)],
        startPoint: .top,
        endPoint: .bottom
    )

    static let cardGradient = LinearGradient(
        colors: [softWhite, cream.opacity(0.4)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let premiumGradient = LinearGradient(
        colors: [gold, Color(red: 0.70, green: 0.56, blue: 0.25)],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let splashGradient = LinearGradient(
        colors: [sageDark, Color(red: 0.22, green: 0.32, blue: 0.30)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Typography
    static let titleFont = Font.system(.largeTitle, design: .serif, weight: .bold)
    static let headlineFont = Font.system(.title2, design: .serif, weight: .semibold)
    static let subheadlineFont = Font.system(.headline, design: .serif, weight: .medium)
    static let bodyFont = Font.system(.body, design: .default)
    static let captionFont = Font.system(.caption, design: .default)
    static let scriptureFont = Font.system(.body, design: .serif).italic()

    // MARK: - Spacing
    static let paddingSmall: CGFloat = 8
    static let paddingMedium: CGFloat = 16
    static let paddingLarge: CGFloat = 24
    static let paddingXLarge: CGFloat = 32
    static let cornerRadius: CGFloat = 16
    static let cornerRadiusSmall: CGFloat = 10

    // MARK: - Shadows
    static let cardShadow = Color.black.opacity(0.06)
    static let cardShadowRadius: CGFloat = 8
}

// MARK: - Card Modifier
struct AJCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(AJTheme.paddingMedium)
            .background(AJTheme.cardBackground)
            .cornerRadius(AJTheme.cornerRadius)
            .shadow(color: AJTheme.cardShadow, radius: AJTheme.cardShadowRadius, x: 0, y: 2)
    }
}

// MARK: - Button Styles
struct AJPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.body, design: .serif, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(AJTheme.sage)
            .cornerRadius(AJTheme.cornerRadius)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct AJSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.body, design: .serif, weight: .semibold))
            .foregroundColor(AJTheme.sage)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(AJTheme.sage.opacity(0.1))
            .cornerRadius(AJTheme.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AJTheme.cornerRadius)
                    .stroke(AJTheme.sage.opacity(0.3), lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.85 : 1.0)
    }
}

struct AJPremiumButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.body, design: .serif, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(AJTheme.premiumGradient)
            .cornerRadius(AJTheme.cornerRadius)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
    }
}

// MARK: - View Extensions
extension View {
    func ajCard() -> some View {
        modifier(AJCardModifier())
    }

    func ajScreenBackground() -> some View {
        self.background(AJTheme.background.ignoresSafeArea())
    }
}
