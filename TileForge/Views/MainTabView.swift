import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settingsVM: SettingsViewModel
    @State private var selectedTab = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                DashboardView()
                    .tag(0)
                ProjectsView()
                    .tag(1)
                TasksView()
                    .tag(2)
                ReportsView()
                    .tag(3)
                SettingsView()
                    .tag(4)
            }
            .background(Color.bgPrimary)

            // Custom Tab Bar
            CustomTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(.keyboard)
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: Int

    let tabs: [(icon: String, label: String)] = [
        ("square.grid.2x2.fill", "Dashboard"),
        ("folder.fill", "Projects"),
        ("checkmark.circle.fill", "Tasks"),
        ("chart.bar.fill", "Reports"),
        ("gearshape.fill", "Settings"),
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { i in
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { selectedTab = i }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tabs[i].icon)
                            .font(.system(size: 22, weight: selectedTab == i ? .bold : .regular))
                            .foregroundColor(selectedTab == i ? .accentBlue : .textInactive)
                            .scaleEffect(selectedTab == i ? 1.15 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedTab)

                        Text(tabs[i].label)
                            .font(AppFont.medium(10))
                            .foregroundColor(selectedTab == i ? .accentBlue : .textInactive)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 8)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.cardWhite)
                .shadow(color: Color.black.opacity(0.10), radius: 16, y: -4)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}
