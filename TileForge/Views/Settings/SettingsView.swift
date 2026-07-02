import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settingsVM: SettingsViewModel
    @EnvironmentObject var projectVM: ProjectViewModel
    @State private var showSaved = false
    @State private var showResetConfirm = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Theme
                    SettingsSection(title: "Appearance") {
                        VStack(spacing: 0) {
                            SettingsLabel(icon: "circle.lefthalf.filled", title: "Theme", iconColor: .accentBlue)
                            HStack(spacing: 8) {
                                ForEach([("Light", "light"), ("Dark", "dark"), ("System", "system")], id: \.1) { label, mode in
                                    Button {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            settingsVM.setTheme(mode)
                                        }
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: mode == "light" ? "sun.max" : mode == "dark" ? "moon" : "iphone")
                                                .font(.system(size: 12))
                                            Text(label).font(AppFont.medium(13))
                                        }
                                        .foregroundColor(settingsVM.themeModePublished == mode ? .white : .textSecondary)
                                        .padding(.horizontal, 12).padding(.vertical, 8)
                                        .frame(maxWidth: .infinity)
                                        .background(settingsVM.themeModePublished == mode ? Color.accentBlue : Color.bgSecondary)
                                        .cornerRadius(10)
                                    }
                                }
                            }
                            .padding(.horizontal, 16).padding(.bottom, 14)
                        }
                    }

                    // Units
                    SettingsSection(title: "Measurements") {
                        VStack(spacing: 0) {
                            PickerRow(icon: "ruler", title: "Units", iconColor: .accentOrange, selection: $settingsVM.units, options: [("Metric (m, mm)", "metric"), ("Imperial (ft, in)", "imperial")])
                            Divider().padding(.leading, 52)
                            PickerRow(icon: "eurosign.circle", title: "Currency", iconColor: .statusDone, selection: $settingsVM.currency, options: [("EUR €", "EUR"), ("USD $", "USD"), ("GBP £", "GBP"), ("RUB ₽", "RUB")])
                            Divider().padding(.leading, 52)
                            SliderRow(icon: "exclamationmark.triangle", title: "Waste Buffer", iconColor: .statusWarning, value: $settingsVM.wasteBuffer, min: 5, max: 30, suffix: "%")
                        }
                    }

                    // Notifications
                    SettingsSection(title: "Notifications") {
                        VStack(spacing: 0) {
                            ToggleRow(icon: "bell.badge", title: "Deadline Alerts", iconColor: .statusError, isOn: $settingsVM.notifDeadlines) {
                                settingsVM.requestNotifications()
                            }
                            Divider().padding(.leading, 52)
                            ToggleRow(icon: "exclamationmark.shield", title: "Warning Alerts", iconColor: .statusWarning, isOn: $settingsVM.notifWarnings) {}
                            Divider().padding(.leading, 52)
                            ToggleRow(icon: "calendar.badge.clock", title: "Weekly Check", iconColor: .accentBlue, isOn: $settingsVM.notifWeekly) {
                                settingsVM.scheduleWeeklyNotification()
                            }
                        }
                    }

                    // Data
                    SettingsSection(title: "Data") {
                        VStack(spacing: 0) {
                            NavigationLink(destination: DataBackupView()) {
                                SettingsNavRow(icon: "externaldrive.badge.checkmark", title: "Backup & Export", iconColor: .accentBlue)
                            }
                            Divider().padding(.leading, 52)
                            Button {
                                showResetConfirm = true
                            } label: {
                                SettingsNavRow(icon: "arrow.counterclockwise", title: "Reset Demo Data", iconColor: .accentOrange)
                            }
                        }
                    }

                    // About
                    SettingsSection(title: "About") {
                        VStack(spacing: 0) {
                            HStack {
                                SettingsLabel(icon: "info.circle", title: "Version", iconColor: .textSecondary)
                                Spacer()
                                Text("1.0.0").font(AppFont.regular(14)).foregroundColor(.textSecondary).padding(.trailing, 16)
                            }
                            Divider().padding(.leading, 52)
                            HStack {
                                SettingsLabel(icon: "hammer.fill", title: "Build", iconColor: .textSecondary)
                                Spacer()
                                Text("Tile Forge").font(AppFont.regular(14)).foregroundColor(.textSecondary).padding(.trailing, 16)
                            }
                        }
                    }

                    if showSaved {
                        HStack {
                            Image(systemName: "checkmark.circle.fill").foregroundColor(.statusDone)
                            Text("Settings saved").font(AppFont.medium(14)).foregroundColor(.statusDone)
                        }
                        .padding(12).background(Color.statusDone.opacity(0.1)).cornerRadius(12)
                        .padding(.horizontal, 18)
                        .transition(.opacity.combined(with: .scale))
                    }

                    Spacer().frame(height: 100)
                }
                .padding(.top, 16)
            }
            .background(Color.bgPrimary.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
        .navigationViewStyle(.stack)
        .alert("Reset Data", isPresented: $showResetConfirm) {
            Button("Reset", role: .destructive) {
                UserDefaults.standard.removeObject(forKey: "tf_projects")
                UserDefaults.standard.removeObject(forKey: "tf_tasks")
                projectVM.loadDemoData()
                withAnimation { showSaved = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { withAnimation { showSaved = false } }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will reset all data to demo state. This cannot be undone.")
        }
    }
}

// MARK: - Settings Components
struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(AppFont.medium(13)).foregroundColor(.textSecondary).padding(.horizontal, 18)
            TFCard { content }.padding(.horizontal, 18)
        }
    }
}

struct SettingsLabel: View {
    let icon: String; let title: String; let iconColor: Color
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8).fill(iconColor.opacity(0.15)).frame(width: 32, height: 32)
                Image(systemName: icon).font(.system(size: 14, weight: .semibold)).foregroundColor(iconColor)
            }
            Text(title).font(AppFont.medium(15)).foregroundColor(.textPrimary)
            Spacer()
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }
}

struct ToggleRow: View {
    let icon: String; let title: String; let iconColor: Color
    @Binding var isOn: Bool
    var onChange: () -> Void = {}
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8).fill(iconColor.opacity(0.15)).frame(width: 32, height: 32)
                Image(systemName: icon).font(.system(size: 14, weight: .semibold)).foregroundColor(iconColor)
            }
            Text(title).font(AppFont.medium(15)).foregroundColor(.textPrimary)
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .onChange(of: isOn) { _ in onChange() }
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
    }
}

struct PickerRow: View {
    let icon: String; let title: String; let iconColor: Color
    @Binding var selection: String
    let options: [(String, String)]
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8).fill(iconColor.opacity(0.15)).frame(width: 32, height: 32)
                Image(systemName: icon).font(.system(size: 14, weight: .semibold)).foregroundColor(iconColor)
            }
            Text(title).font(AppFont.medium(15)).foregroundColor(.textPrimary)
            Spacer()
            Picker("", selection: $selection) {
                ForEach(options, id: \.1) { label, val in Text(label).tag(val) }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .accentColor(.accentBlue)
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
    }
}

struct SliderRow: View {
    let icon: String; let title: String; let iconColor: Color
    @Binding var value: Double
    let min: Double; let max: Double; let suffix: String
    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8).fill(iconColor.opacity(0.15)).frame(width: 32, height: 32)
                    Image(systemName: icon).font(.system(size: 14, weight: .semibold)).foregroundColor(iconColor)
                }
                Text(title).font(AppFont.medium(15)).foregroundColor(.textPrimary)
                Spacer()
                Text("\(Int(value))\(suffix)").font(AppFont.bold(14)).foregroundColor(.accentBlue)
            }
            Slider(value: $value, in: min...max, step: 1).accentColor(.accentBlue).padding(.leading, 44)
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
    }
}

struct SettingsNavRow: View {
    let icon: String; let title: String; let iconColor: Color
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8).fill(iconColor.opacity(0.15)).frame(width: 32, height: 32)
                Image(systemName: icon).font(.system(size: 14, weight: .semibold)).foregroundColor(iconColor)
            }
            Text(title).font(AppFont.medium(15)).foregroundColor(.textPrimary)
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold)).foregroundColor(.textInactive)
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
    }
}

// MARK: - Data Backup
struct DataBackupView: View {
    @EnvironmentObject var projectVM: ProjectViewModel
    @State private var exported = false

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                TFCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Data Overview")
                            .font(AppFont.semibold(16)).foregroundColor(.textPrimary)
                        InfoItem(label: "Projects", value: "\(projectVM.projects.count)")
                        InfoItem(label: "Tasks", value: "\(projectVM.tasks.count)")
                        InfoItem(label: "Photos", value: "\(projectVM.photos.count)")
                    }
                    .padding(16)
                }
                .padding(.horizontal, 18)

                Button {
                    exportData()
                } label: {
                    HStack { Image(systemName: "square.and.arrow.up"); Text("Export All Data") }
                }
                .buttonStyle(PrimaryButtonStyle()).padding(.horizontal, 18)

                if exported {
                    Text("Data exported successfully!")
                        .font(AppFont.medium(14)).foregroundColor(.statusDone)
                        .padding().background(Color.statusDone.opacity(0.1)).cornerRadius(12)
                        .padding(.horizontal, 18)
                }
            }
            .padding(.top, 24)
        }
        .background(Color.bgPrimary.ignoresSafeArea())
        .navigationTitle("Backup & Export")
        .navigationBarTitleDisplayMode(.inline)
    }

    func exportData() {
        guard let data = try? JSONEncoder().encode(projectVM.projects),
              let str = String(data: data, encoding: .utf8) else { return }
        let av = UIActivityViewController(activityItems: [str], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(av, animated: true)
        }
        withAnimation { exported = true }
    }
}
