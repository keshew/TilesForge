import SwiftUI
import Combine
import Network

struct SplashView: View {

    @StateObject private var viewModel = Bedside()
    @State private var networkMonitor = NWPathMonitor()
    @State private var cancellables = Set<AnyCancellable>()
    @State private var isVisible = true
    @State private var pulse = false

    var body: some View {
        ZStack {
            TilesBackground()

            VStack(spacing: 0) {
                Spacer()
                SoftGridLogo()
                    .scaleEffect(pulse ? 1.0 : 0.92)
                    .animation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true), value: pulse)
                Spacer()
                Text("LOADING...")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.45), radius: 3, y: 2)
                    .padding(.bottom, 72)
            }
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
        .fullScreenCover(isPresented: $viewModel.showPermissionPrompt) {
            TilesConsentView(viewModel: viewModel)
        }
        .fullScreenCover(isPresented: $viewModel.showOfflineView) {
            TilesOfflineView()
        }
        .fullScreenCover(isPresented: $viewModel.navigateToWeb) {
            ScopeView()
        }
        .fullScreenCover(isPresented: $viewModel.navigateToMain) {
            RootView()
        }
        .onAppear {
            NotificationCenter.default.publisher(for: .pulseArrived)
                .compactMap { $0.userInfo?["conversionData"] as? [String: Any] }
                .sink { data in
                    viewModel.ingestPulse(data)
                }
                .store(in: &cancellables)

            NotificationCenter.default.publisher(for: .tracesArrived)
                .compactMap { $0.userInfo?["deeplinksData"] as? [String: Any] }
                .sink { data in
                    viewModel.ingestTraces(data)
                }
                .store(in: &cancellables)

            setupNetworkMonitoring()
            viewModel.ignite()
            pulse = true
        }
        .onDisappear {
            isVisible = false
            networkMonitor.cancel()
        }
    }

    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { path in
            Task { @MainActor in
                viewModel.networkConnectivityChanged(path.status == .satisfied)
            }
        }
        networkMonitor.start(queue: .global(qos: .background))
    }
}

#Preview("Loading") {
    SplashView()
}
