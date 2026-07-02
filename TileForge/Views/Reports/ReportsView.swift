import SwiftUI

struct ReportsView: View {
    @EnvironmentObject var projectVM: ProjectViewModel
    @State private var selectedTab = 0
    @State private var appeared = false
    @State private var showExportSheet = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Overview cards
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ReportStatCard(value: "\(projectVM.activeProjects.count)", label: "Active Projects", icon: "folder.fill", color: .accentBlue, trend: nil)
                        ReportStatCard(value: "\(projectVM.totalRooms)", label: "Total Rooms", icon: "door.left.hand.open", color: .accentOrange, trend: nil)
                        ReportStatCard(value: String(format: "%.0f m²", projectVM.totalArea), label: "Total Area", icon: "square.dashed", color: .statusDone, trend: nil)
                        ReportStatCard(value: "\(projectVM.doneTasks.count)/\(projectVM.tasks.count)", label: "Tasks Done", icon: "checkmark.circle.fill", color: .statusWarning, trend: nil)
                    }
                    .padding(.horizontal, 18)
                    .offset(y: appeared ? 0 : 20).opacity(appeared ? 1 : 0)

                    // Status by room
                    TFCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Status by Room")
                                .font(AppFont.semibold(16)).foregroundColor(.textPrimary)

                            let statuses: [(ProjectStatus, Int)] = {
                                var counts = [ProjectStatus: Int]()
                                for p in projectVM.activeProjects {
                                    for r in p.rooms { counts[r.status, default: 0] += 1 }
                                }
                                return counts.sorted { $0.key.rawValue < $1.key.rawValue }
                            }()

                            let total = statuses.reduce(0) { $0 + $1.1 }

                            ForEach(statuses, id: \.0) { status, count in
                                VStack(spacing: 4) {
                                    HStack {
                                        Circle().fill(status.color).frame(width: 8, height: 8)
                                        Text(status.label).font(AppFont.medium(13)).foregroundColor(.textPrimary)
                                        Spacer()
                                        Text("\(count) rooms").font(AppFont.regular(13)).foregroundColor(.textSecondary)
                                        Text("\(total > 0 ? Int(Double(count)/Double(total)*100) : 0)%")
                                            .font(AppFont.bold(13)).foregroundColor(status.color)
                                    }
                                    ProgressView(value: total > 0 ? Double(count)/Double(total) : 0)
                                        .progressViewStyle(LinearProgressViewStyle(tint: status.color))
                                }
                            }

                            if statuses.isEmpty {
                                Text("No rooms yet. Add rooms to see status breakdown.")
                                    .font(AppFont.regular(13)).foregroundColor(.textSecondary)
                            }
                        }
                        .padding(16)
                    }
                    .padding(.horizontal, 18)
                    .offset(y: appeared ? 0 : 20).opacity(appeared ? 1 : 0)

                    // Tile usage per project
                    TFCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Area by Project")
                                .font(AppFont.semibold(16)).foregroundColor(.textPrimary)

                            let maxArea = projectVM.activeProjects.map { $0.totalArea }.max() ?? 1

                            ForEach(projectVM.activeProjects) { project in
                                VStack(spacing: 4) {
                                    HStack {
                                        Text(project.name).font(AppFont.medium(13)).foregroundColor(.textPrimary).lineLimit(1)
                                        Spacer()
                                        Text(String(format: "%.1f m²", project.totalArea)).font(AppFont.regular(13)).foregroundColor(.textSecondary)
                                    }
                                    ProgressView(value: maxArea > 0 ? project.totalArea / maxArea : 0)
                                        .progressViewStyle(LinearProgressViewStyle(tint: .accentBlue))
                                }
                            }

                            if projectVM.activeProjects.isEmpty {
                                Text("No active projects.").font(AppFont.regular(13)).foregroundColor(.textSecondary)
                            }
                        }
                        .padding(16)
                    }
                    .padding(.horizontal, 18)
                    .offset(y: appeared ? 0 : 20).opacity(appeared ? 1 : 0)

                    // Tasks progress
                    TFCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Tasks Progress")
                                .font(AppFont.semibold(16)).foregroundColor(.textPrimary)

                            let total = projectVM.tasks.count
                            let done = projectVM.doneTasks.count
                            let overdue = projectVM.overdueTasks.count
                            let pending = projectVM.pendingTasks.count - overdue

                            if total == 0 {
                                Text("No tasks yet.").font(AppFont.regular(13)).foregroundColor(.textSecondary)
                            } else {
                                // Pie-like breakdown
                                HStack(spacing: 20) {
                                    ZStack {
                                        Circle().stroke(Color.bgSecondary, lineWidth: 12).frame(width: 90, height: 90)
                                        if total > 0 {
                                            Circle()
                                                .trim(from: 0, to: CGFloat(done) / CGFloat(total))
                                                .stroke(Color.statusDone, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                                                .frame(width: 90, height: 90).rotationEffect(.degrees(-90))
                                        }
                                        VStack(spacing: 0) {
                                            Text("\(Int(Double(done)/Double(max(1,total))*100))%")
                                                .font(AppFont.bold(18)).foregroundColor(.textPrimary)
                                            Text("done").font(AppFont.regular(10)).foregroundColor(.textSecondary)
                                        }
                                    }

                                    VStack(alignment: .leading, spacing: 8) {
                                        TaskStatRow(label: "Done", count: done, color: .statusDone)
                                        TaskStatRow(label: "Pending", count: pending, color: .accentBlue)
                                        TaskStatRow(label: "Overdue", count: overdue, color: .statusError)
                                    }
                                    Spacer()
                                }
                            }
                        }
                        .padding(16)
                    }
                    .padding(.horizontal, 18)
                    .offset(y: appeared ? 0 : 20).opacity(appeared ? 1 : 0)

                    // History log
                    TFCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent Activity")
                                .font(AppFont.semibold(16)).foregroundColor(.textPrimary)

                            ForEach(projectVM.activeProjects.prefix(5)) { project in
                                HStack(spacing: 12) {
                                    Circle()
                                        .fill(project.status.color.opacity(0.2))
                                        .frame(width: 32, height: 32)
                                        .overlay(Image(systemName: "pencil").font(.system(size: 12)).foregroundColor(project.status.color))

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Updated: \(project.name)").font(AppFont.medium(13)).foregroundColor(.textPrimary)
                                        Text(project.updatedAt, style: .relative).font(AppFont.regular(11)).foregroundColor(.textSecondary)
                                    }
                                    Spacer()
                                }
                            }
                            if projectVM.activeProjects.isEmpty {
                                Text("No recent activity.").font(AppFont.regular(13)).foregroundColor(.textSecondary)
                            }
                        }
                        .padding(16)
                    }
                    .padding(.horizontal, 18)

                    // Export
                    VStack(spacing: 12) {
                        Button {
                            showExportSheet = true
                        } label: {
                            HStack {
                                Image(systemName: "doc.text.fill")
                                Text("Export Report")
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())

                        Button {
                            // Share summary text
                            let text = generateReportText()
                            let av = UIActivityViewController(activityItems: [text], applicationActivities: nil)
                            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                               let window = windowScene.windows.first {
                                window.rootViewController?.present(av, animated: true)
                            }
                        } label: {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share Summary")
                            }
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
                    .padding(.horizontal, 18)

                    Spacer().frame(height: 100)
                }
                .padding(.top, 16)
            }
            .background(Color.bgPrimary.ignoresSafeArea())
            .navigationTitle("Reports")
            .navigationBarTitleDisplayMode(.large)
        }
        .navigationViewStyle(.stack)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) { appeared = true }
        }
        .sheet(isPresented: $showExportSheet) {
            ExportReportView()
        }
    }

    func generateReportText() -> String {
        var text = "=== TILE FORGE REPORT ===\n\n"
        text += "Projects: \(projectVM.activeProjects.count)\n"
        text += "Total Rooms: \(projectVM.totalRooms)\n"
        text += String(format: "Total Area: %.1f m²\n", projectVM.totalArea)
        text += "Tasks Done: \(projectVM.doneTasks.count)/\(projectVM.tasks.count)\n\n"
        for project in projectVM.activeProjects {
            text += "Project: \(project.name) [\(project.status.rawValue)]\n"
            for room in project.rooms {
                text += "  Room: \(room.name) - \(room.areaFormatted)\n"
                if let lc = room.layoutConfig {
                    text += "  Layout: \(lc.pattern.rawValue), \(lc.tileSize.name)\n"
                }
            }
            text += "\n"
        }
        return text
    }
}

struct ReportStatCard: View {
    let value: String; let label: String; let icon: String; let color: Color; let trend: String?
    var body: some View {
        TFCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: icon).font(.system(size: 18, weight: .semibold)).foregroundColor(color)
                    Spacer()
                    if let t = trend { Text(t).font(AppFont.medium(12)).foregroundColor(.statusDone) }
                }
                Text(value).font(AppFont.bold(22)).foregroundColor(.textPrimary)
                Text(label).font(AppFont.regular(12)).foregroundColor(.textSecondary).lineLimit(2)
            }
            .padding(14)
        }
    }
}

struct TaskStatRow: View {
    let label: String; let count: Int; let color: Color
    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).font(AppFont.regular(13)).foregroundColor(.textSecondary)
            Spacer()
            Text("\(count)").font(AppFont.bold(13)).foregroundColor(.textPrimary)
        }
    }
}

// MARK: - Export Report
struct ExportReportView: View {
    @Environment(\.presentationMode) var dismiss
    @EnvironmentObject var projectVM: ProjectViewModel
    @State private var includeRooms = true
    @State private var includeLayouts = true
    @State private var includeTasks = true
    @State private var exported = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 18) {
                    TFCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Report Contents")
                                .font(AppFont.semibold(16)).foregroundColor(.textPrimary)
                            Toggle("Include Rooms", isOn: $includeRooms).font(AppFont.medium(14))
                            Toggle("Include Layouts", isOn: $includeLayouts).font(AppFont.medium(14))
                            Toggle("Include Tasks", isOn: $includeTasks).font(AppFont.medium(14))
                        }
                        .padding(16)
                    }
                    .padding(.horizontal, 18)

                    if exported {
                        TFCard {
                            HStack {
                                Image(systemName: "checkmark.circle.fill").foregroundColor(.statusDone).font(.system(size: 20))
                                Text("Report exported successfully").font(AppFont.medium(14)).foregroundColor(.statusDone)
                            }
                            .padding(16)
                        }
                        .padding(.horizontal, 18)
                        .transition(.opacity.combined(with: .scale))
                    }

                    Button("Export as Text") {
                        exportReport()
                    }.buttonStyle(PrimaryButtonStyle()).padding(.horizontal, 18)
                }
                .padding(.top, 24)
            }
            .background(Color.bgPrimary.ignoresSafeArea())
            .navigationTitle("Export Report").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Close") { dismiss.wrappedValue.dismiss() }.foregroundColor(.accentBlue) } }
        }
    }

    func exportReport() {
        var text = "TILE FORGE — PROJECT REPORT\n"
        text += "Generated: \(Date().formatted())\n\n"
        for project in projectVM.activeProjects {
            text += "PROJECT: \(project.name)\n"
            text += "Status: \(project.status.rawValue) | Type: \(project.objectType.rawValue)\n"
            if includeRooms {
                text += "ROOMS:\n"
                for room in project.rooms {
                    text += "  - \(room.name): \(room.areaFormatted)\n"
                    if includeLayouts, let lc = room.layoutConfig {
                        text += "    Layout: \(lc.pattern.rawValue), \(lc.tileSize.name), grout \(lc.groutMM)mm\n"
                    }
                }
            }
            text += "\n"
        }
        if includeTasks {
            text += "TASKS (\(projectVM.doneTasks.count) done / \(projectVM.tasks.count) total):\n"
            for task in projectVM.tasks {
                text += "  [\(task.isDone ? "x" : " ")] \(task.title)\n"
            }
        }

        let av = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(av, animated: true)
        }
        withAnimation { exported = true }
    }
}
