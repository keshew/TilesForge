import SwiftUI

@main
struct TileForgeApp: App {
    @UIApplicationDelegateAdaptor(TileForgeAppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()
    @StateObject private var projectVM = ProjectViewModel()
    @StateObject private var settingsVM = SettingsViewModel()

    var body: some Scene {
        WindowGroup {
            SplashView()
                .environmentObject(appState)
                .environmentObject(projectVM)
                .environmentObject(settingsVM)
                .preferredColorScheme(settingsVM.colorScheme)
        }
    }
}

struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        ZStack {
            if !hasCompletedOnboarding {
                OnboardingView()
                    .transition(.opacity)
            } else {
                MainTabView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: hasCompletedOnboarding)
    }
}
