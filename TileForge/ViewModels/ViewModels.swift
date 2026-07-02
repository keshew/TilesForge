import SwiftUI
import Combine
import UserNotifications

// MARK: - AppState
class AppState: ObservableObject {
    @Published var selectedProjectID: UUID?
    @Published var showingQuickCheck = false
}

// MARK: - Settings ViewModel
class SettingsViewModel: ObservableObject {
    @AppStorage("themeMode") private var themeMode: String = "system"
    @AppStorage("units") var units: String = "metric"
    @AppStorage("currency") var currency: String = "EUR"
    @AppStorage("notifDeadlines") var notifDeadlines: Bool = true
    @AppStorage("notifWarnings") var notifWarnings: Bool = true
    @AppStorage("notifWeekly") var notifWeekly: Bool = true
    @AppStorage("wasteBuffer") var wasteBuffer: Double = 10.0

    @Published var themeModePublished: String = "system" {
        didSet { themeMode = themeModePublished }
    }

    init() {
        themeModePublished = themeMode
    }

    var colorScheme: ColorScheme? {
        switch themeMode {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    func setTheme(_ mode: String) {
        themeMode = mode
        themeModePublished = mode
    }

    func requestNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                if granted {
                    self.scheduleWeeklyNotification()
                }
            }
        }
    }

    func scheduleWeeklyNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["weekly_check"])
        guard notifWeekly else { return }
        let content = UNMutableNotificationContent()
        content.title = "Tile Forge Weekly Check"
        content.body = "Review your active projects and update progress."
        content.sound = .default
        var dateComponents = DateComponents()
        dateComponents.weekday = 2
        dateComponents.hour = 9
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "weekly_check", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func scheduleDeadlineNotification(for task: TFTask) {
        guard notifDeadlines, let due = task.dueDate else { return }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [task.id.uuidString])
        let content = UNMutableNotificationContent()
        content.title = "Task Due: \(task.title)"
        content.body = "Don't forget to complete this task."
        content.sound = .default
        let triggerDate = Calendar.current.date(byAdding: .hour, value: -24, to: due) ?? due
        guard triggerDate > Date() else { return }
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: triggerDate.timeIntervalSinceNow, repeats: false)
        let request = UNNotificationRequest(identifier: task.id.uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}

// MARK: - Project ViewModel
class ProjectViewModel: ObservableObject {
    @Published var projects: [Project] = []
    @Published var tasks: [TFTask] = []
    @Published var photos: [PhotoEntry] = []

    private let projectsKey = "tf_projects"
    private let tasksKey = "tf_tasks"
    private let photosKey = "tf_photos"

    init() {
        load()
        if projects.isEmpty { loadDemoData() }
    }

    // MARK: - Persistence
    func save() {
        if let data = try? JSONEncoder().encode(projects) { UserDefaults.standard.set(data, forKey: projectsKey) }
        if let data = try? JSONEncoder().encode(tasks) { UserDefaults.standard.set(data, forKey: tasksKey) }
        if let data = try? JSONEncoder().encode(photos) { UserDefaults.standard.set(data, forKey: photosKey) }
    }

    func load() {
        if let data = UserDefaults.standard.data(forKey: projectsKey),
           let decoded = try? JSONDecoder().decode([Project].self, from: data) {
            projects = decoded
        }
        if let data = UserDefaults.standard.data(forKey: tasksKey),
           let decoded = try? JSONDecoder().decode([TFTask].self, from: data) {
            tasks = decoded
        }
        if let data = UserDefaults.standard.data(forKey: photosKey),
           let decoded = try? JSONDecoder().decode([PhotoEntry].self, from: data) {
            photos = decoded
        }
    }

    // MARK: - Projects
    func addProject(_ project: Project) {
        projects.insert(project, at: 0)
        save()
    }

    func updateProject(_ project: Project) {
        if let idx = projects.firstIndex(where: { $0.id == project.id }) {
            var p = project
            p.updatedAt = Date()
            projects[idx] = p
        }
        save()
    }

    func deleteProject(_ project: Project) {
        projects.removeAll { $0.id == project.id }
        tasks.removeAll { $0.projectID == project.id }
        save()
    }

    func archiveProject(_ project: Project) {
        if let idx = projects.firstIndex(where: { $0.id == project.id }) {
            projects[idx].status = .archived
            projects[idx].updatedAt = Date()
        }
        save()
    }

    var activeProjects: [Project] { projects.filter { $0.status != .archived } }
    var archivedProjects: [Project] { projects.filter { $0.status == .archived } }

    // MARK: - Rooms
    func addRoom(_ room: Room, to projectID: UUID) {
        if let idx = projects.firstIndex(where: { $0.id == projectID }) {
            projects[idx].rooms.append(room)
            projects[idx].updatedAt = Date()
        }
        save()
    }

    func updateRoom(_ room: Room, in projectID: UUID) {
        if let pIdx = projects.firstIndex(where: { $0.id == projectID }),
           let rIdx = projects[pIdx].rooms.firstIndex(where: { $0.id == room.id }) {
            projects[pIdx].rooms[rIdx] = room
            projects[pIdx].updatedAt = Date()
        }
        save()
    }

    func deleteRoom(_ roomID: UUID, from projectID: UUID) {
        if let pIdx = projects.firstIndex(where: { $0.id == projectID }) {
            projects[pIdx].rooms.removeAll { $0.id == roomID }
            projects[pIdx].updatedAt = Date()
        }
        save()
    }

    // MARK: - Layout
    func saveLayout(_ config: LayoutConfig, roomID: UUID, projectID: UUID) {
        if let pIdx = projects.firstIndex(where: { $0.id == projectID }),
           let rIdx = projects[pIdx].rooms.firstIndex(where: { $0.id == roomID }) {
            projects[pIdx].rooms[rIdx].layoutConfig = config
            projects[pIdx].updatedAt = Date()
        }
        save()
    }

    // MARK: - Records
    func addRecord(_ record: Record, to projectID: UUID) {
        if let pIdx = projects.firstIndex(where: { $0.id == projectID }) {
            let roomID = record.roomID
            if let rIdx = projects[pIdx].rooms.firstIndex(where: { $0.id == roomID }) {
                projects[pIdx].rooms[rIdx].records.append(record)
            } else {
                // attach to first room if no specific room
                if !projects[pIdx].rooms.isEmpty {
                    projects[pIdx].rooms[0].records.append(record)
                }
            }
            projects[pIdx].updatedAt = Date()
        }
        save()
    }

    func deleteRecord(_ recordID: UUID, from projectID: UUID) {
        if let pIdx = projects.firstIndex(where: { $0.id == projectID }) {
            for rIdx in projects[pIdx].rooms.indices {
                projects[pIdx].rooms[rIdx].records.removeAll { $0.id == recordID }
            }
        }
        save()
    }

    // MARK: - Tasks
    func addTask(_ task: TFTask) {
        tasks.insert(task, at: 0)
        save()
    }

    func updateTask(_ task: TFTask) {
        if let idx = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[idx] = task
        }
        save()
    }

    func deleteTask(_ task: TFTask) {
        tasks.removeAll { $0.id == task.id }
        save()
    }

    func toggleTaskDone(_ taskID: UUID) {
        if let idx = tasks.firstIndex(where: { $0.id == taskID }) {
            tasks[idx].isDone.toggle()
        }
        save()
    }

    var todayTasks: [TFTask] { tasks.filter { $0.isDueToday } }
    var overdueTasks: [TFTask] { tasks.filter { $0.isOverdue } }
    var doneTasks: [TFTask] { tasks.filter { $0.isDone } }
    var pendingTasks: [TFTask] { tasks.filter { !$0.isDone } }

    // MARK: - Photos
    func addPhoto(_ photo: PhotoEntry) {
        photos.insert(photo, at: 0)
        save()
    }

    func deletePhoto(_ photo: PhotoEntry) {
        photos.removeAll { $0.id == photo.id }
        save()
    }

    func photos(for projectID: UUID) -> [PhotoEntry] { photos.filter { $0.projectID == projectID } }

    // MARK: - Stats
    var totalArea: Double { activeProjects.reduce(0) { $0 + $1.totalArea } }
    var totalRooms: Int { activeProjects.reduce(0) { $0 + $1.roomCount } }

    // MARK: - Demo Data
    func loadDemoData() {
        var bathroom = Room(name: "Bathroom", floor: 1, widthM: 2.4, lengthM: 3.2, notes: "Main bathroom")
        bathroom.status = .active
        var kitchen = Room(name: "Kitchen", floor: 1, widthM: 3.5, lengthM: 4.8, notes: "Open kitchen")
        kitchen.status = .planning

        var layout = LayoutConfig.default
        layout.tileSize = TileSize.presets[1]
        layout.pattern = .offset
        bathroom.layoutConfig = layout

        var project = Project(name: "Home Renovation", objectType: .apartment, address: "Valencia, Spain", startDate: Date(), notes: "Full apartment renovation", status: .active)
        project.rooms = [bathroom, kitchen]
        projects = [project]

        var t1 = TFTask(title: "Order bathroom tiles", projectID: project.id, dueDate: Calendar.current.date(byAdding: .day, value: 3, to: Date()), priority: .high)
        var t2 = TFTask(title: "Measure kitchen floor", projectID: project.id, dueDate: Date(), priority: .medium)
        var t3 = TFTask(title: "Compare layout schemes", priority: .low)
        tasks = [t1, t2, t3]
        save()
    }
}

// MARK: - Layout Calculator
class TileLayoutCalculator {
    static func calculate(room: Room, config: LayoutConfig) -> TileLayoutResult {
        let roomW = room.widthM * 1000  // to mm
        let roomH = room.lengthM * 1000
        let tileW = config.tileSize.widthMM + config.groutMM
        let tileH = config.tileSize.heightMM + config.groutMM

        var tilesPerRow = 0
        var tilesPerColumn = 0
        var leftEdge = 0.0
        var rightEdge = 0.0
        var topEdge = 0.0
        var bottomEdge = 0.0

        switch config.pattern {
        case .straight, .basketweave:
            let startXOffset = tileW * config.startX
            leftEdge = startXOffset > 0 ? startXOffset : tileW
            if leftEdge > tileW { leftEdge = leftEdge.truncatingRemainder(dividingBy: tileW) }
            if leftEdge < 1 { leftEdge = tileW }
            rightEdge = (roomW - leftEdge).truncatingRemainder(dividingBy: tileW)
            if rightEdge < 1 { rightEdge = tileW }

            let startYOffset = tileH * config.startY
            topEdge = startYOffset > 0 ? startYOffset : tileH
            if topEdge > tileH { topEdge = topEdge.truncatingRemainder(dividingBy: tileH) }
            if topEdge < 1 { topEdge = tileH }
            bottomEdge = (roomH - topEdge).truncatingRemainder(dividingBy: tileH)
            if bottomEdge < 1 { bottomEdge = tileH }

        case .offset, .offset13:
            let fraction: Double = config.pattern == .offset ? 0.5 : 1.0/3.0
            leftEdge = tileW * config.startX
            if leftEdge < 1 { leftEdge = tileW * fraction }
            rightEdge = (roomW - leftEdge).truncatingRemainder(dividingBy: tileW)
            if rightEdge < 1 { rightEdge = tileW }
            topEdge = tileH * config.startY
            if topEdge < 1 { topEdge = tileH / 2 }
            bottomEdge = (roomH - topEdge).truncatingRemainder(dividingBy: tileH)
            if bottomEdge < 1 { bottomEdge = tileH }

        case .diagonal:
            let diagTile = sqrt(tileW * tileW + tileH * tileH)
            leftEdge = diagTile * 0.5
            rightEdge = (roomW - leftEdge).truncatingRemainder(dividingBy: diagTile)
            if rightEdge < 1 { rightEdge = diagTile }
            topEdge = diagTile * 0.5
            bottomEdge = (roomH - topEdge).truncatingRemainder(dividingBy: diagTile)
            if bottomEdge < 1 { bottomEdge = diagTile }

        case .herringbone:
            leftEdge = tileW * 0.5
            rightEdge = (roomW - leftEdge).truncatingRemainder(dividingBy: tileW)
            if rightEdge < 1 { rightEdge = tileW }
            topEdge = tileH * 0.5
            bottomEdge = (roomH - topEdge).truncatingRemainder(dividingBy: tileH)
            if bottomEdge < 1 { bottomEdge = tileH }
        }

        let innerW = roomW - leftEdge - rightEdge
        let innerH = roomH - topEdge - bottomEdge
        tilesPerRow = max(1, Int(ceil(innerW / tileW)) + 2)
        tilesPerColumn = max(1, Int(ceil(innerH / tileH)) + 2)

        let fullTiles = Int(floor(innerW / tileW)) * Int(floor(innerH / tileH))
        let totalTiles = tilesPerRow * tilesPerColumn
        let cutTiles = totalTiles - fullTiles

        let usedArea = Double(fullTiles) * config.tileSize.widthMM * config.tileSize.heightMM
        let roomArea = roomW * roomH
        let wastePercent = max(0, (1 - usedArea / roomArea)) * 100

        let gridCells = generateGrid(rows: min(tilesPerColumn, 20), cols: min(tilesPerRow, 15), leftEdge: leftEdge, rightEdge: rightEdge, topEdge: topEdge, bottomEdge: bottomEdge, tileW: tileW, tileH: tileH)

        return TileLayoutResult(
            fullTiles: fullTiles,
            cutTiles: cutTiles,
            totalTiles: totalTiles,
            wastePercent: wastePercent,
            leftEdgeMM: leftEdge,
            rightEdgeMM: rightEdge,
            topEdgeMM: topEdge,
            bottomEdgeMM: bottomEdge,
            tilesPerRow: tilesPerRow,
            tilesPerColumn: tilesPerColumn,
            gridCells: gridCells
        )
    }

    private static func generateGrid(rows: Int, cols: Int, leftEdge: Double, rightEdge: Double, topEdge: Double, bottomEdge: Double, tileW: Double, tileH: Double) -> [[TileLayoutResult.TileCellType]] {
        var grid: [[TileLayoutResult.TileCellType]] = []
        for r in 0..<rows {
            var row: [TileLayoutResult.TileCellType] = []
            for c in 0..<cols {
                let isLeftEdge = c == 0 && leftEdge < tileW * 0.95
                let isRightEdge = c == cols - 1 && rightEdge < tileW * 0.95
                let isTopEdge = r == 0 && topEdge < tileH * 0.95
                let isBottomEdge = r == rows - 1 && bottomEdge < tileH * 0.95

                let type: TileLayoutResult.TileCellType
                if (isLeftEdge || isRightEdge) && (isTopEdge || isBottomEdge) {
                    type = .corner
                } else if isLeftEdge { type = .cutLeft }
                else if isRightEdge { type = .cutRight }
                else if isTopEdge { type = .cutTop }
                else if isBottomEdge { type = .cutBottom }
                else { type = .full }
                row.append(type)
            }
            grid.append(row)
        }
        return grid
    }
}
