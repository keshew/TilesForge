import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var projectVM: ProjectViewModel
    @EnvironmentObject var appState: AppState
    @State private var showAddProject = false
    @State private var appeared = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Tile Forge")
                                .font(AppFont.bold(28))
                                .foregroundColor(.textPrimary)
                            Text("Smart layout planning")
                                .font(AppFont.regular(14))
                                .foregroundColor(.textSecondary)
                        }
                        Spacer()
                        Button { showAddProject = true } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.accentBlue)
                        }
                        .buttonStyle(IconButtonStyle())
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 8)

                    // Stats row
                    HStack(spacing: 12) {
                        StatCard(value: "\(projectVM.activeProjects.count)", label: "Projects", icon: "folder.fill", color: .accentBlue)
                        StatCard(value: "\(projectVM.totalRooms)", label: "Rooms", icon: "door.left.hand.open", color: .accentOrange)
                        StatCard(value: "\(projectVM.pendingTasks.count)", label: "Tasks", icon: "checkmark.circle", color: .statusDone)
                    }
                    .padding(.horizontal, 18)
                    .offset(y: appeared ? 0 : 20)
                    .opacity(appeared ? 1 : 0)

                    // Active Project
                    if let project = projectVM.activeProjects.first {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Active Project")
                                .padding(.horizontal, 18)

                            NavigationLink(destination: ProjectDetailView(project: project)) {
                                ActiveProjectCard(project: project)
                                    .padding(.horizontal, 18)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .offset(y: appeared ? 0 : 20)
                        .opacity(appeared ? 1 : 0)
                    }

                    // Today's Tasks
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "Today Actions", action: "See All")
                            .padding(.horizontal, 18)

                        if projectVM.todayTasks.isEmpty && projectVM.overdueTasks.isEmpty {
                            TFCard {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.statusDone)
                                        .font(.system(size: 20))
                                    Text("All caught up! No tasks today.")
                                        .font(AppFont.medium(14))
                                        .foregroundColor(.textSecondary)
                                    Spacer()
                                }
                                .padding(16)
                            }
                            .padding(.horizontal, 18)
                        } else {
                            ForEach(projectVM.overdueTasks.prefix(2)) { task in
                                TaskRowCard(task: task)
                                    .padding(.horizontal, 18)
                            }
                            ForEach(projectVM.todayTasks.prefix(2)) { task in
                                TaskRowCard(task: task)
                                    .padding(.horizontal, 18)
                            }
                        }
                    }
                    .offset(y: appeared ? 0 : 20)
                    .opacity(appeared ? 1 : 0)

                    // Warnings
                    if !projectVM.overdueTasks.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Warnings")
                                .padding(.horizontal, 18)

                            TFCard {
                                HStack(spacing: 12) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.statusError)
                                        .font(.system(size: 20))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("\(projectVM.overdueTasks.count) overdue tasks")
                                            .font(AppFont.semibold(14))
                                            .foregroundColor(.textPrimary)
                                        Text("Review and reschedule")
                                            .font(AppFont.regular(12))
                                            .foregroundColor(.textSecondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.textInactive)
                                }
                                .padding(16)
                            }
                            .padding(.horizontal, 18)
                        }
                    }

                    // Quick actions
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "Quick Actions")
                            .padding(.horizontal, 18)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                QuickActionButton(icon: "plus.app.fill", label: "Add Project", color: .accentBlue) {
                                    showAddProject = true
                                }
                                if let p = projectVM.activeProjects.first, let r = p.rooms.first {
                                    NavigationLink(destination: LayoutGeneratorView(room: r, project: p)) {
                                        QuickActionChip(icon: "square.grid.3x3.fill", label: "Layout", color: .accentOrange)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                NavigationLink(destination: ReportsView()) {
                                    QuickActionChip(icon: "chart.bar.fill", label: "Reports", color: .statusDone)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.horizontal, 18)
                        }
                    }
                    .offset(y: appeared ? 0 : 20)
                    .opacity(appeared ? 1 : 0)

                    Spacer().frame(height: 100)
                }
                .padding(.top, 12)
            }
            .background(Color.bgPrimary.ignoresSafeArea())
            .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack)
        .sheet(isPresented: $showAddProject) {
            AddProjectView()
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) { appeared = true }
        }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        TFCard {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(color)
                Text(value)
                    .font(AppFont.bold(24))
                    .foregroundColor(.textPrimary)
                Text(label)
                    .font(AppFont.medium(12))
                    .foregroundColor(.textSecondary)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Active Project Card
struct ActiveProjectCard: View {
    let project: Project

    var progress: Double {
        let total = project.rooms.count
        guard total > 0 else { return 0 }
        let done = project.rooms.filter { $0.status == .completed }.count
        return Double(done) / Double(total)
    }

    var body: some View {
        TFCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(project.name)
                            .font(AppFont.bold(18))
                            .foregroundColor(.textPrimary)
                        Text(project.objectType.rawValue)
                            .font(AppFont.regular(13))
                            .foregroundColor(.textSecondary)
                    }
                    Spacer()
                    StatusBadge(status: project.status)
                }

                HStack(spacing: 16) {
                    Label("\(project.roomCount) rooms", systemImage: "door.left.hand.open")
                    Label(String(format: "%.1f m²", project.totalArea), systemImage: "square.dashed")
                }
                .font(AppFont.medium(13))
                .foregroundColor(.textSecondary)

                // Progress
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Rooms complete")
                            .font(AppFont.medium(12))
                            .foregroundColor(.textSecondary)
                        Spacer()
                        Text("\(Int(progress * 100))%")
                            .font(AppFont.bold(12))
                            .foregroundColor(.accentBlue)
                    }
                    ProgressView(value: progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .accentBlue))
                }
            }
            .padding(16)
        }
    }
}

// MARK: - Task Row Card
struct TaskRowCard: View {
    let task: TFTask
    @EnvironmentObject var projectVM: ProjectViewModel

    var body: some View {
        TFCard {
            HStack(spacing: 12) {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        projectVM.toggleTaskDone(task.id)
                    }
                } label: {
                    Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 22))
                        .foregroundColor(task.isDone ? .statusDone : .textInactive)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(task.title)
                        .font(AppFont.medium(14))
                        .foregroundColor(.textPrimary)
                        .strikethrough(task.isDone)
                    if let due = task.dueDate {
                        Text(due, style: .date)
                            .font(AppFont.regular(12))
                            .foregroundColor(task.isOverdue ? .statusError : .textSecondary)
                    }
                }
                Spacer()
                Circle()
                    .fill(task.priority.color)
                    .frame(width: 8, height: 8)
            }
            .padding(14)
        }
    }
}

// MARK: - Quick Action
struct QuickActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            QuickActionChip(icon: icon, label: label, color: color)
        }
    }
}

struct QuickActionChip: View {
    let icon: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
            Text(label)
                .font(AppFont.semibold(13))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(color)
        .cornerRadius(12)
        .shadow(color: color.opacity(0.3), radius: 6, y: 3)
    }
}
