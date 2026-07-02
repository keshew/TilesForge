import SwiftUI

struct SoftGridLogo: View {
    var compact = false

    var body: some View {
        VStack(spacing: compact ? -8 : -10) {
            Text("SOFT")
                .font(.system(size: compact ? 48 : 64, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(colors: [Color(hex: "#FFD42A"), Color(hex: "#FF8500")], startPoint: .top, endPoint: .bottom)
                )
                .overlay(
                    Text("SOFT")
                        .font(.system(size: compact ? 48 : 64, weight: .black, design: .rounded))
                        .foregroundColor(.clear)
                        .shadow(color: Color(hex: "#A44700"), radius: 0, x: 0, y: 3)
                )
            Text("GRID")
                .font(.system(size: compact ? 48 : 64, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(colors: [Color(hex: "#2B8DFF"), Color(hex: "#0457F6")], startPoint: .top, endPoint: .bottom)
                )
                .overlay(
                    Text("GRID")
                        .font(.system(size: compact ? 48 : 64, weight: .black, design: .rounded))
                        .foregroundColor(.clear)
                        .shadow(color: Color.black.opacity(0.9), radius: 0, x: 0, y: 3)
                )
        }
        .shadow(color: .black.opacity(0.9), radius: 1, x: 0, y: 2)
        .multilineTextAlignment(.center)
    }
}
