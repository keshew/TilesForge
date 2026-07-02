import SwiftUI

struct TilesOfflineView: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                TilesBackground()

                VStack(spacing: 14) {
                    Text("ERROR")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.15))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color(hex: "#FFD51D"), lineWidth: 4))
                        .shadow(color: .black.opacity(0.45), radius: 3, y: 2)

                    Text("PLEASE, CHECK YOUR\nINTERNET\nCONNECTION AND\nRESTART")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.black.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(hex: "#FFD51D"), lineWidth: 3)
                        )
                        .shadow(color: .black.opacity(0.45), radius: 3, y: 2)
                }
                .frame(width: min(geometry.size.width * 0.72, 360))
            }
            .ignoresSafeArea()
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
    }
}

#Preview("No Internet") {
    TilesOfflineView()
}
