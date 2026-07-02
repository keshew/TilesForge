import SwiftUI

struct TilesConsentView: View {
    let viewModel: Bedside

    var body: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height

            ZStack {
                TilesBackground()

                VStack(spacing: 0) {
                    Spacer(minLength: isLandscape ? 12 : 0)

                    SoftGridLogo(compact: isLandscape)

                    Spacer()
                        .frame(height: isLandscape ? 10 : geometry.size.height * 0.10)

                    consentText(isLandscape: isLandscape)

                    Spacer()
                        .frame(height: isLandscape ? 10 : 16)

                    actionButton

                    Spacer()
                        .frame(height: isLandscape ? 9 : 12)

                    skipButton

                    Spacer(minLength: isLandscape ? 12 : geometry.size.height * 0.08)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, isLandscape ? 32 : 28)
            }
            .ignoresSafeArea()
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
    }

    private func consentText(isLandscape: Bool) -> some View {
        VStack(spacing: isLandscape ? 8 : 12) {
            Text("ALLOW NOTIFICATIONS ABOUT\nBONUSES AND PROMOS")
                .font(.system(size: isLandscape ? 14 : 16, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .shadow(color: .black.opacity(0.65), radius: 2, y: 1)

            Text("STAY TUNED WITH BEST OFFERS FROM\nOUR CASINO")
                .font(.system(size: isLandscape ? 8 : 10, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .shadow(color: .black.opacity(0.65), radius: 2, y: 1)
        }
    }

    private var actionButton: some View {
        Button {
            viewModel.acceptConsent()
        } label: {
            Text("YES, I WANT BONUSES!")
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .frame(width: 260, height: 34)
                .background(Color(hex: "#FF8900"))
                .clipShape(RoundedRectangle(cornerRadius: 9))
                .overlay(
                    RoundedRectangle(cornerRadius: 9)
                        .stroke(Color(hex: "#FFD51D"), lineWidth: 4)
                )
                .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var skipButton: some View {
        Button {
            viewModel.skipConsent()
        } label: {
            Text("SKIP")
                .font(.system(size: 10, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.75), radius: 2, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview("Notifications") {
    TilesConsentView(viewModel: Bedside())
}
