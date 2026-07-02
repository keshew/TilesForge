import SwiftUI

// MARK: - Color Palette
extension Color {
    // Backgrounds
    static let bgPrimary = Color(hex: "#F8FAFC")
    static let bgSecondary = Color(hex: "#EEF2F7")
    static let bgDepth = Color(hex: "#E5EAF2")
    static let cardWhite = Color(hex: "#FFFFFF")
    static let cardSecondary = Color(hex: "#F1F5F9")
    static let divider = Color(hex: "#E2E8F0")
    static let dividerDeep = Color(hex: "#CBD5E1")

    // Blue Accent
    static let accentBlue = Color(hex: "#3B82F6")
    static let accentBlueActive = Color(hex: "#2563EB")
    static let accentBlueSoft = Color(hex: "#60A5FA")

    // Orange Accent
    static let accentOrange = Color(hex: "#F97316")
    static let accentOrangeSoft = Color(hex: "#FB923C")
    static let accentOrangeLight = Color(hex: "#FDBA74")

    // Status Colors
    static let statusDone = Color(hex: "#22C55E")
    static let statusActive = Color(hex: "#3B82F6")
    static let statusWarning = Color(hex: "#FACC15")
    static let statusError = Color(hex: "#EF4444")

    // Text
    static let textPrimary = Color(hex: "#0F172A")
    static let textSecondary = Color(hex: "#475569")
    static let textInactive = Color(hex: "#94A3B8")

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
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}

// MARK: - Typography
struct AppFont {
    static func bold(_ size: CGFloat) -> Font { .system(size: size, weight: .bold, design: .rounded) }
    static func semibold(_ size: CGFloat) -> Font { .system(size: size, weight: .semibold, design: .rounded) }
    static func medium(_ size: CGFloat) -> Font { .system(size: size, weight: .medium, design: .rounded) }
    static func regular(_ size: CGFloat) -> Font { .system(size: size, weight: .regular, design: .rounded) }
    static func mono(_ size: CGFloat) -> Font { .system(size: size, weight: .medium, design: .monospaced) }
}

// MARK: - Custom Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    var color: Color = .accentBlue
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFont.semibold(16))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(color)
            .cornerRadius(14)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
            .shadow(color: color.opacity(0.3), radius: 8, y: 4)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFont.semibold(16))
            .foregroundColor(.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(Color.divider)
            .cornerRadius(14)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct IconButtonStyle: ButtonStyle {
    var color: Color = .accentBlue
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(color)
            .scaleEffect(configuration.isPressed ? 0.88 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Card View
struct TFCard<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        content
            .background(Color.cardWhite)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Status Badge
struct StatusBadge: View {
    let status: ProjectStatus
    var body: some View {
        Text(status.label)
            .font(AppFont.medium(11))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(status.color)
            .cornerRadius(6)
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    var action: String? = nil
    var onAction: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(AppFont.bold(18))
                .foregroundColor(.textPrimary)
            Spacer()
            if let action = action {
                Button(action: { onAction?() }) {
                    Text(action)
                        .font(AppFont.medium(14))
                        .foregroundColor(.accentBlue)
                }
            }
        }
    }
}

// MARK: - Input Field
struct TFTextField: View {
    let title: String
    @Binding var text: String
    var placeholder: String = ""
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(AppFont.medium(13))
                .foregroundColor(.textSecondary)
            TextField(placeholder.isEmpty ? title : placeholder, text: $text)
                .font(AppFont.regular(16))
                .foregroundColor(.textPrimary)
                .keyboardType(keyboardType)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.bgSecondary)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.divider, lineWidth: 1))
        }
    }
}

// MARK: - Empty State
struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    var action: String? = nil
    var onAction: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 52))
                .foregroundColor(.textInactive)
            VStack(spacing: 6) {
                Text(title).font(AppFont.bold(18)).foregroundColor(.textPrimary)
                Text(subtitle).font(AppFont.regular(14)).foregroundColor(.textSecondary).multilineTextAlignment(.center)
            }
            if let action = action {
                Button(action: { onAction?() }) { Text(action) }
                    .buttonStyle(PrimaryButtonStyle())
                    .frame(maxWidth: 200)
            }
        }
        .padding(32)
    }
}
