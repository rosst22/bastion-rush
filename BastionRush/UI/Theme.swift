import SwiftUI

enum AppTheme {
    static let navy = Color(red: 0.035, green: 0.065, blue: 0.14)
    static let panel = Color(red: 0.07, green: 0.11, blue: 0.20)
    static let cobalt = Color(red: 0.12, green: 0.43, blue: 0.94)
    static let cyan = Color(red: 0.14, green: 0.78, blue: 0.94)
    static let gold = Color(red: 1.0, green: 0.69, blue: 0.18)
    static let coral = Color(red: 0.94, green: 0.25, blue: 0.28)
    static let ivory = Color(red: 0.94, green: 0.94, blue: 0.88)
}

struct PanelModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(18)
            .background(AppTheme.panel.opacity(0.96), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(.white.opacity(0.08), lineWidth: 1)
            }
    }
}

extension View {
    func gamePanel() -> some View { modifier(PanelModifier()) }
}
