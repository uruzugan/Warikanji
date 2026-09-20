import SwiftUI

enum AppTheme {
    static let primary = Color(red: 0.39, green: 0.40, blue: 0.95)
    static let secondary = Color(red: 0.55, green: 0.36, blue: 0.96)
    static let success = Color(red: 0.06, green: 0.73, blue: 0.55)
    static let warning = Color(red: 0.98, green: 0.63, blue: 0.08)
    static let danger = Color(red: 0.94, green: 0.27, blue: 0.27)

    static let background = Color(uiColor: .systemGroupedBackground)
    static let card = Color(uiColor: .secondarySystemGroupedBackground)

    static let gradient = LinearGradient(
        colors: [primary, secondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

struct AppCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(AppTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .black.opacity(0.05), radius: 8, y: 3)
    }
}

struct AppInputModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(12)
            .background(Color(uiColor: .tertiarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

extension View {
    func appCard() -> some View {
        modifier(AppCardModifier())
    }

    func inputStyle() -> some View {
        modifier(AppInputModifier())
    }
}
