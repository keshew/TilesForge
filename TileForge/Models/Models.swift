import SwiftUI
import Foundation

// MARK: - Enums

enum ProjectStatus: String, Codable, CaseIterable {
    case active = "Active"
    case planning = "Planning"
    case paused = "Paused"
    case completed = "Completed"
    case archived = "Archived"

    var label: String { rawValue }
    var color: Color {
        switch self {
        case .active: return .statusActive
        case .planning: return .accentOrange
        case .paused: return .statusWarning
        case .completed: return .statusDone
        case .archived: return .textInactive
        }
    }
}

enum ObjectType: String, Codable, CaseIterable {
    case apartment = "Apartment"
    case house = "House"
    case office = "Office"
    case bathroom = "Bathroom"
    case kitchen = "Kitchen"
    case other = "Other"
}

enum TilePattern: String, Codable, CaseIterable {
    case straight = "Straight"
    case offset = "Offset (1/2)"
    case offset13 = "Offset (1/3)"
    case diagonal = "Diagonal 45°"
    case herringbone = "Herringbone"
    case basketweave = "Basketweave"

    var description: String {
        switch self {
        case .straight: return "Classic grid layout"
        case .offset: return "Brick pattern, half offset"
        case .offset13: return "One-third offset"
        case .diagonal: return "45 degree rotation"
        case .herringbone: return "V-shaped interlocking"
        case .basketweave: return "Woven appearance"
        }
    }
    var icon: String {
        switch self {
        case .straight: return "square.grid.3x3"
        case .offset: return "rectangle.grid.2x2"
        case .diagonal: return "diamond.fill"
        case .herringbone: return "arrow.up.and.down.and.arrow.left.and.right"
        case .offset13: return "rectangle.grid.1x2"
        case .basketweave: return "square.grid.2x2"
        }
    }
}

enum RecordCategory: String, Codable, CaseIterable {
    case measurement = "Measurement"
    case purchase = "Purchase"
    case issue = "Issue"
    case note = "Note"
    case inspection = "Inspection"

    var icon: String {
        switch self {
        case .measurement: return "ruler"
        case .purchase: return "cart"
        case .issue: return "exclamationmark.triangle"
        case .note: return "note.text"
        case .inspection: return "checkmark.shield"
        }
    }
    var color: Color {
        switch self {
        case .measurement: return .accentBlue
        case .purchase: return .statusDone
        case .issue: return .statusError
        case .note: return .accentOrange
        case .inspection: return .statusWarning
        }
    }
}

enum TaskPriority: String, Codable, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"

    var color: Color {
        switch self {
        case .low: return .statusDone
        case .medium: return .statusWarning
        case .high: return .statusError
        }
    }
}

enum PhotoCategory: String, Codable, CaseIterable {
    case before = "Before"
    case problem = "Problem"
    case progress = "Progress"
    case after = "After"

    var color: Color {
        switch self {
        case .before: return .textSecondary
        case .problem: return .statusError
        case .progress: return .accentBlue
        case .after: return .statusDone
        }
    }
}

// MARK: - Tile Model
struct TileSize: Codable, Identifiable, Hashable {
    var id = UUID()
    var widthMM: Double   // in mm
    var heightMM: Double  // in mm
    var name: String

    static let presets: [TileSize] = [
        TileSize(widthMM: 200, heightMM: 200, name: "20×20 cm"),
        TileSize(widthMM: 300, heightMM: 300, name: "30×30 cm"),
        TileSize(widthMM: 450, heightMM: 450, name: "45×45 cm"),
        TileSize(widthMM: 600, heightMM: 600, name: "60×60 cm"),
        TileSize(widthMM: 300, heightMM: 600, name: "30×60 cm"),
        TileSize(widthMM: 200, heightMM: 400, name: "20×40 cm"),
        TileSize(widthMM: 150, heightMM: 150, name: "15×15 cm"),
        TileSize(widthMM: 750, heightMM: 750, name: "75×75 cm"),
        TileSize(widthMM: 1200, heightMM: 600, name: "120×60 cm"),
    ]
}

// MARK: - Layout Result
struct TileLayoutResult: Codable {
    var fullTiles: Int
    var cutTiles: Int
    var totalTiles: Int
    var wastePercent: Double
    var leftEdgeMM: Double
    var rightEdgeMM: Double
    var topEdgeMM: Double
    var bottomEdgeMM: Double
    var tilesPerRow: Int
    var tilesPerColumn: Int
    var gridCells: [[TileCellType]]

    enum TileCellType: String, Codable {
        case full, cutLeft, cutRight, cutTop, cutBottom, corner, cutDiag
    }
}

// MARK: - Project Model
struct Project: Identifiable, Codable {
    var id = UUID()
    var name: String
    var objectType: ObjectType
    var address: String
    var startDate: Date
    var notes: String
    var status: ProjectStatus
    var createdAt: Date
    var updatedAt: Date
    var rooms: [Room]

    init(name: String, objectType: ObjectType = .apartment, address: String = "", startDate: Date = Date(), notes: String = "", status: ProjectStatus = .planning) {
        self.name = name
        self.objectType = objectType
        self.address = address
        self.startDate = startDate
        self.notes = notes
        self.status = status
        self.createdAt = Date()
        self.updatedAt = Date()
        self.rooms = []
    }

    var totalArea: Double { rooms.reduce(0) { $0 + $1.area } }
    var roomCount: Int { rooms.count }
}

// MARK: - Room Model
struct Room: Identifiable, Codable {
    var id = UUID()
    var name: String
    var floor: Int
    var widthM: Double   // meters
    var lengthM: Double  // meters
    var notes: String
    var status: ProjectStatus
    var records: [Record]
    var layoutConfig: LayoutConfig?
    var photoIDs: [String]

    init(name: String, floor: Int = 1, widthM: Double = 0, lengthM: Double = 0, notes: String = "", status: ProjectStatus = .planning) {
        self.name = name
        self.floor = floor
        self.widthM = widthM
        self.lengthM = lengthM
        self.notes = notes
        self.status = status
        self.records = []
        self.photoIDs = []
    }

    var area: Double { widthM * lengthM }
    var areaFormatted: String { String(format: "%.1f m²", area) }
}

// MARK: - Layout Config
struct LayoutConfig: Codable {
    var tileSize: TileSize
    var groutMM: Double
    var pattern: TilePattern
    var startX: Double  // 0..1 fraction offset
    var startY: Double  // 0..1 fraction offset
    var rotationDeg: Double

    static var `default`: LayoutConfig {
        LayoutConfig(tileSize: TileSize.presets[2], groutMM: 3, pattern: .straight, startX: 0.5, startY: 0.5, rotationDeg: 0)
    }
}

// MARK: - Record Model
struct Record: Identifiable, Codable {
    var id = UUID()
    var title: String
    var roomID: UUID?
    var date: Date
    var category: RecordCategory
    var value: String
    var comment: String
    var status: ProjectStatus
    var photoID: String?
    var createdAt: Date

    init(title: String, roomID: UUID? = nil, date: Date = Date(), category: RecordCategory = .note, value: String = "", comment: String = "") {
        self.title = title
        self.roomID = roomID
        self.date = date
        self.category = category
        self.value = value
        self.comment = comment
        self.status = .active
        self.createdAt = Date()
    }
}

// MARK: - Task Model
struct TFTask: Identifiable, Codable {
    var id = UUID()
    var title: String
    var projectID: UUID?
    var roomID: UUID?
    var dueDate: Date?
    var priority: TaskPriority
    var isDone: Bool
    var notes: String
    var createdAt: Date

    init(title: String, projectID: UUID? = nil, roomID: UUID? = nil, dueDate: Date? = nil, priority: TaskPriority = .medium, notes: String = "") {
        self.title = title
        self.projectID = projectID
        self.roomID = roomID
        self.dueDate = dueDate
        self.priority = priority
        self.isDone = false
        self.notes = notes
        self.createdAt = Date()
    }

    var isOverdue: Bool {
        guard let due = dueDate else { return false }
        return due < Date() && !isDone
    }
    var isDueToday: Bool {
        guard let due = dueDate else { return false }
        return Calendar.current.isDateInToday(due) && !isDone
    }
}

// MARK: - Photo Entry
struct PhotoEntry: Identifiable, Codable {
    var id = UUID()
    var projectID: UUID
    var roomID: UUID?
    var category: PhotoCategory
    var caption: String
    var createdAt: Date
    var imageData: Data?
}

// MARK: - Notification Setting
struct NotificationSetting: Codable {
    var deadlinesEnabled: Bool = true
    var warningsEnabled: Bool = true
    var weeklyCheckEnabled: Bool = true
    var weeklyCheckDay: Int = 1  // 1 = Monday
    var weeklyCheckHour: Int = 9
}
