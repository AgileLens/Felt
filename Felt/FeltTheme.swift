import SwiftUI

enum FeltTheme {
    static let accent = Color("AccentColor")

    static let background = Color(light: .init(red: 0.97, green: 0.96, blue: 0.98),
                                   dark: .init(red: 0.08, green: 0.07, blue: 0.10))

    static let cardBackground = Color(light: .white,
                                       dark: .init(red: 0.14, green: 0.13, blue: 0.16))

    static let subtleText = Color(light: .init(red: 0.52, green: 0.48, blue: 0.55),
                                   dark: .init(red: 0.58, green: 0.55, blue: 0.62))

    static let cardRadius: CGFloat = 20
}

extension Color {
    init(light: Color, dark: Color) {
        #if os(iOS) || os(visionOS)
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(dark) : UIColor(light)
        })
        #elseif os(macOS)
        self.init(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .vibrantDark]) != nil
                ? NSColor(dark) : NSColor(light)
        })
        #endif
    }
}

struct FeltCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(FeltTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: FeltTheme.cardRadius, style: .continuous))
            .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}

extension View {
    func feltCard() -> some View {
        modifier(FeltCardStyle())
    }
}
