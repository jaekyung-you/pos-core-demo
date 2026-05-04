import SwiftUI

public enum TDS {
    // MARK: - Colors
    public enum Color {
        public static let blue500     = SwiftUI.Color(hex: "#3182F6")
        public static let blue50      = SwiftUI.Color(hex: "#EEF4FF")
        public static let gray900     = SwiftUI.Color(hex: "#191F28")
        public static let gray700     = SwiftUI.Color(hex: "#4E5968")
        public static let gray400     = SwiftUI.Color(hex: "#8B95A1")
        public static let gray200     = SwiftUI.Color(hex: "#E8EBED")
        public static let gray100     = SwiftUI.Color(hex: "#F2F4F6")
        public static let gray50      = SwiftUI.Color(hex: "#F8F9FA")
        public static let red500      = SwiftUI.Color(hex: "#F04452")
        public static let white       = SwiftUI.Color.white
    }

    // MARK: - Spacing (8pt grid)
    public enum Spacing {
        public static let xs: CGFloat   = 4
        public static let sm: CGFloat   = 8
        public static let md: CGFloat   = 12
        public static let lg: CGFloat   = 16
        public static let xl: CGFloat   = 20
        public static let xxl: CGFloat  = 24
        public static let xxxl: CGFloat = 32
    }

    // MARK: - Corner Radius
    public enum Radius {
        public static let card: CGFloat   = 16
        public static let button: CGFloat = 14
        public static let input: CGFloat  = 10
        public static let badge: CGFloat  = 8
        public static let tag: CGFloat    = 6
    }
}

public extension SwiftUI.Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

public extension View {
    func tdsCardStyle() -> some View {
        self
            .background(TDS.Color.white)
            .clipShape(RoundedRectangle(cornerRadius: TDS.Radius.card))
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}
