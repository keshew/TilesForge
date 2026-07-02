import SwiftUI

// MARK: - Projects List
struct ProjectsView: View {
    @EnvironmentObject var projectVM: ProjectViewModel
    @State private var showAddProject = false
    @State private var showArchived = false
    @State private var searchText = ""

    var filteredProjects: [Project] {
        let list = showArchived ? projectVM.archivedProjects : projectVM.activeProjects
        if searchText.isEmpty { return list }
        return list.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search
                HStack {
                    Image(systemName: "magnifyingglass").foregroundColor(.textInactive)
                    TextField("Search projects...", text: $searchText)
                        .font(AppFont.regular(15))
                }
                .padding(12)
                .background(Color.bgSecondary)
                .cornerRadius(12)
                .padding(.horizontal, 18)
                .padding(.top, 8)

                // Filter toggle
                HStack {
                    Button {
                        withAnimation { showArchived = false }
                    } label: {
                        Text("Active")
                            .font(AppFont.semibold(14))
                            .foregroundColor(showArchived ? .textSecondary : .white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 7)
                            .background(showArchived ? Color.clear : Color.accentBlue)
                            .cornerRadius(10)
                    }
                    Button {
                        withAnimation { showArchived = true }
                    } label: {
                        Text("Archived")
                            .font(AppFont.semibold(14))
                            .foregroundColor(showArchived ? .white : .textSecondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 7)
                            .background(showArchived ? Color.accentBlue : Color.clear)
                            .cornerRadius(10)
                    }
                    Spacer()
                    Text("\(filteredProjects.count) projects")
                        .font(AppFont.regular(13))
                        .foregroundColor(.textSecondary)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 10)

                if filteredProjects.isEmpty {
                    Spacer()
                    EmptyStateView(
                        icon: "folder.badge.plus",
                        title: "No Projects",
                        subtitle: "Create your first tiling project to get started.",
                        action: "Add Project",
                        onAction: { showAddProject = true }
                    )
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredProjects) { project in
                                NavigationLink(destination: ProjectDetailView(project: project)) {
                                    ProjectCard(project: project)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        withAnimation { projectVM.deleteProject(project) }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    Button {
                                        withAnimation { projectVM.archiveProject(project) }
                                    } label: {
                                        Label("Archive", systemImage: "archivebox")
                                    }
                                    .tint(.accentOrange)
                                }
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 8)
                        .padding(.bottom, 100)
                    }
                }
            }
            .background(Color.bgPrimary.ignoresSafeArea())
            .navigationTitle("Projects")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showAddProject = true } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.accentBlue)
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
        .sheet(isPresented: $showAddProject) { AddProjectView() }
    }
}

// MARK: - Project Card
struct ProjectCard: View {
    let project: Project

    var body: some View {
        TFCard {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(project.status.color.opacity(0.15))
                        .frame(width: 48, height: 48)
                    Image(systemName: "square.grid.3x3.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(project.status.color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(project.name)
                        .font(AppFont.semibold(16))
                        .foregroundColor(.textPrimary)
                    HStack(spacing: 8) {
                        Text(project.objectType.rawValue)
                            .font(AppFont.regular(13))
                            .foregroundColor(.textSecondary)
                        Text("·")
                            .foregroundColor(.textInactive)
                        Text("\(project.roomCount) rooms")
                            .font(AppFont.regular(13))
                            .foregroundColor(.textSecondary)
                    }
                    Text(project.updatedAt, style: .relative)
                        .font(AppFont.regular(11))
                        .foregroundColor(.textInactive)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    StatusBadge(status: project.status)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.textInactive)
                }
            }
            .padding(14)
        }
    }
}

// MARK: - Add Project
struct AddProjectView: View {
    @EnvironmentObject var projectVM: ProjectViewModel
    @Environment(\.presentationMode) var dismiss
    @State private var name = ""
    @State private var objectType = ObjectType.apartment
    @State private var address = ""
    @State private var startDate = Date()
    @State private var notes = ""
    @State private var status = ProjectStatus.planning
    @State private var showValidation = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 18) {
                    TFTextField(title: "Project Name", text: $name, placeholder: "e.g. Home Renovation")
                    if showValidation && name.isEmpty {
                        Text("Project name is required")
                            .font(AppFont.regular(12))
                            .foregroundColor(.statusError)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Object Type")
                            .font(AppFont.medium(13))
                            .foregroundColor(.textSecondary)
                        Picker("", selection: $objectType) {
                            ForEach(ObjectType.allCases, id: \.self) { t in
                                Text(t.rawValue).tag(t)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    TFTextField(title: "Address / Label", text: $address, placeholder: "e.g. Valencia, Apt 3")

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Start Date")
                            .font(AppFont.medium(13))
                            .foregroundColor(.textSecondary)
                        DatePicker("", selection: $startDate, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .padding(12)
                            .background(Color.bgSecondary)
                            .cornerRadius(12)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Status")
                            .font(AppFont.medium(13))
                            .foregroundColor(.textSecondary)
                        Picker("", selection: $status) {
                            ForEach([ProjectStatus.planning, .active, .paused], id: \.self) { s in
                                Text(s.label).tag(s)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Notes")
                            .font(AppFont.medium(13))
                            .foregroundColor(.textSecondary)
                        TextEditor(text: $notes)
                            .font(AppFont.regular(15))
                            .foregroundColor(.textPrimary)
                            .frame(height: 80)
                            .padding(10)
                            .background(Color.bgSecondary)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.divider, lineWidth: 1))
                    }

                    Button("Save Project") {
                        if name.isEmpty { showValidation = true; return }
                        let project = Project(name: name, objectType: objectType, address: address, startDate: startDate, notes: notes, status: status)
                        projectVM.addProject(project)
                        dismiss.wrappedValue.dismiss()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.top, 8)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
            }
            .background(Color.bgPrimary.ignoresSafeArea())
            .navigationTitle("New Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss.wrappedValue.dismiss() }
                        .foregroundColor(.accentBlue)
                }
            }
        }
    }
}

// MARK: - Project Detail
struct ProjectDetailView: View {
    let project: Project
    @EnvironmentObject var projectVM: ProjectViewModel
    @State private var showAddRoom = false
    @State private var showEditProject = false

    var currentProject: Project {
        projectVM.projects.first { $0.id == project.id } ?? project
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Project info
                TFCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(currentProject.name)
                                    .font(AppFont.bold(22))
                                    .foregroundColor(.textPrimary)
                                if !currentProject.address.isEmpty {
                                    Label(currentProject.address, systemImage: "mappin.circle")
                                        .font(AppFont.regular(13))
                                        .foregroundColor(.textSecondary)
                                }
                            }
                            Spacer()
                            StatusBadge(status: currentProject.status)
                        }
                        Divider()
                        HStack(spacing: 20) {
                            InfoItem(label: "Type", value: currentProject.objectType.rawValue)
                            InfoItem(label: "Rooms", value: "\(currentProject.roomCount)")
                            InfoItem(label: "Area", value: String(format: "%.1f m²", currentProject.totalArea))
                        }
                        if !currentProject.notes.isEmpty {
                            Text(currentProject.notes)
                                .font(AppFont.regular(13))
                                .foregroundColor(.textSecondary)
                        }
                    }
                    .padding(16)
                }
                .padding(.horizontal, 18)

                // Rooms section
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Rooms", action: "Add Room") { showAddRoom = true }
                        .padding(.horizontal, 18)

                    if currentProject.rooms.isEmpty {
                        TFCard {
                            VStack(spacing: 8) {
                                Image(systemName: "door.left.hand.open")
                                    .font(.system(size: 32))
                                    .foregroundColor(.textInactive)
                                Text("No rooms yet")
                                    .font(AppFont.medium(14))
                                    .foregroundColor(.textSecondary)
                                Button("Add First Room") { showAddRoom = true }
                                    .font(AppFont.semibold(14))
                                    .foregroundColor(.accentBlue)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(24)
                        }
                        .padding(.horizontal, 18)
                    } else {
                        ForEach(currentProject.rooms) { room in
                            NavigationLink(destination: RoomDetailView(room: room, project: currentProject)) {
                                RoomCard(room: room)
                                    .padding(.horizontal, 18)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }

                Spacer().frame(height: 100)
            }
            .padding(.top, 16)
        }
        .background(Color.bgPrimary.ignoresSafeArea())
        .navigationTitle("Project")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showEditProject = true } label: {
                    Image(systemName: "pencil")
                        .foregroundColor(.accentBlue)
                }
            }
        }
        .sheet(isPresented: $showAddRoom) {
            AddRoomView(projectID: currentProject.id)
        }
        .sheet(isPresented: $showEditProject) {
            EditProjectView(project: currentProject)
        }
    }
}

struct InfoItem: View {
    let label: String
    let value: String
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(AppFont.regular(11)).foregroundColor(.textInactive)
            Text(value).font(AppFont.semibold(14)).foregroundColor(.textPrimary)
        }
    }
}

// MARK: - Edit Project
struct EditProjectView: View {
    @EnvironmentObject var projectVM: ProjectViewModel
    @Environment(\.presentationMode) var dismiss
    @State var project: Project

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 18) {
                    TFTextField(title: "Project Name", text: $project.name)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Status").font(AppFont.medium(13)).foregroundColor(.textSecondary)
                        Picker("", selection: $project.status) {
                            ForEach(ProjectStatus.allCases.filter { $0 != .archived }, id: \.self) {
                                Text($0.label).tag($0)
                            }
                        }.pickerStyle(.segmented)
                    }
                    TFTextField(title: "Address", text: $project.address)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Notes").font(AppFont.medium(13)).foregroundColor(.textSecondary)
                        TextEditor(text: $project.notes)
                            .frame(height: 80)
                            .padding(10)
                            .background(Color.bgSecondary)
                            .cornerRadius(12)
                    }
                    Button("Save Changes") {
                        projectVM.updateProject(project)
                        dismiss.wrappedValue.dismiss()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                .padding(.horizontal, 18).padding(.vertical, 16)
            }
            .background(Color.bgPrimary.ignoresSafeArea())
            .navigationTitle("Edit Project").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss.wrappedValue.dismiss() }.foregroundColor(.accentBlue)
                }
            }
        }
    }
}

// MARK: - Room Card
struct RoomCard: View {
    let room: Room
    var body: some View {
        TFCard {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.accentBlue.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: "square.grid.3x3")
                        .foregroundColor(.accentBlue)
                        .font(.system(size: 18, weight: .semibold))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(room.name).font(AppFont.semibold(16)).foregroundColor(.textPrimary)
                    HStack(spacing: 8) {
                        Text(room.areaFormatted).font(AppFont.regular(13)).foregroundColor(.textSecondary)
                        Text("·").foregroundColor(.textInactive)
                        Text("Floor \(room.floor)").font(AppFont.regular(13)).foregroundColor(.textSecondary)
                        if room.layoutConfig != nil {
                            Text("·").foregroundColor(.textInactive)
                            Label("Layout saved", systemImage: "checkmark.circle.fill")
                                .font(AppFont.regular(11))
                                .foregroundColor(.statusDone)
                        }
                    }
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundColor(.textInactive).font(.system(size: 12))
            }
            .padding(14)
        }
    }
}

// MARK: - Add Room
struct AddRoomView: View {
    let projectID: UUID
    @EnvironmentObject var projectVM: ProjectViewModel
    @Environment(\.presentationMode) var dismiss
    @State private var name = ""
    @State private var floor = 1
    @State private var widthText = ""
    @State private var lengthText = ""
    @State private var notes = ""
    @State private var showValidation = false

    var area: Double {
        (Double(widthText) ?? 0) * (Double(lengthText) ?? 0)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 18) {
                    TFTextField(title: "Room Name", text: $name, placeholder: "e.g. Bathroom")
                    if showValidation && name.isEmpty {
                        Text("Room name is required").font(AppFont.regular(12)).foregroundColor(.statusError).frame(maxWidth: .infinity, alignment: .leading)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Floor").font(AppFont.medium(13)).foregroundColor(.textSecondary)
                        Stepper("Floor \(floor)", value: $floor, in: 0...50)
                            .font(AppFont.regular(15))
                            .padding(12).background(Color.bgSecondary).cornerRadius(12)
                    }

                    HStack(spacing: 12) {
                        TFTextField(title: "Width (m)", text: $widthText, placeholder: "e.g. 3.2", keyboardType: .decimalPad)
                        TFTextField(title: "Length (m)", text: $lengthText, placeholder: "e.g. 4.5", keyboardType: .decimalPad)
                    }

                    if area > 0 {
                        HStack {
                            Image(systemName: "square.dashed").foregroundColor(.accentBlue)
                            Text("Area: \(String(format: "%.2f m²", area))")
                                .font(AppFont.semibold(14)).foregroundColor(.accentBlue)
                            Spacer()
                        }
                        .padding(12).background(Color.accentBlue.opacity(0.08)).cornerRadius(10)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Notes").font(AppFont.medium(13)).foregroundColor(.textSecondary)
                        TextEditor(text: $notes).font(AppFont.regular(15)).frame(height: 70)
                            .padding(10).background(Color.bgSecondary).cornerRadius(12)
                    }

                    Button("Save Room") {
                        if name.isEmpty { showValidation = true; return }
                        let room = Room(name: name, floor: floor, widthM: Double(widthText) ?? 0, lengthM: Double(lengthText) ?? 0, notes: notes)
                        projectVM.addRoom(room, to: projectID)
                        dismiss.wrappedValue.dismiss()
                    }
                    .buttonStyle(PrimaryButtonStyle()).padding(.top, 8)
                }
                .padding(.horizontal, 18).padding(.vertical, 16)
            }
            .background(Color.bgPrimary.ignoresSafeArea())
            .navigationTitle("Add Room").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss.wrappedValue.dismiss() }.foregroundColor(.accentBlue)
                }
            }
        }
    }
}

// MARK: - Room Detail
struct RoomDetailView: View {
    let room: Room
    let project: Project
    @EnvironmentObject var projectVM: ProjectViewModel
    @State private var showAddRecord = false
    @State private var showLayoutGenerator = false
    @State private var showEditRoom = false

    var currentRoom: Room {
        projectVM.projects.first { $0.id == project.id }?.rooms.first { $0.id == room.id } ?? room
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Room info card
                TFCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(currentRoom.name).font(AppFont.bold(22)).foregroundColor(.textPrimary)
                            Spacer()
                            StatusBadge(status: currentRoom.status)
                        }
                        HStack(spacing: 20) {
                            InfoItem(label: "Width", value: String(format: "%.2f m", currentRoom.widthM))
                            InfoItem(label: "Length", value: String(format: "%.2f m", currentRoom.lengthM))
                            InfoItem(label: "Area", value: currentRoom.areaFormatted)
                            InfoItem(label: "Floor", value: "\(currentRoom.floor)")
                        }
                        if let config = currentRoom.layoutConfig {
                            Divider()
                            HStack {
                                Image(systemName: "checkmark.circle.fill").foregroundColor(.statusDone)
                                Text("Layout: \(config.pattern.rawValue) • \(config.tileSize.name)")
                                    .font(AppFont.medium(13)).foregroundColor(.statusDone)
                            }
                        }
                    }
                    .padding(16)
                }
                .padding(.horizontal, 18)

                // Layout Generator Button
                Button {
                    showLayoutGenerator = true
                } label: {
                    HStack {
                        Image(systemName: "square.grid.3x3.fill")
                            .font(.system(size: 20))
                        Text(currentRoom.layoutConfig == nil ? "Generate Layout" : "Edit Layout")
                            .font(AppFont.semibold(16))
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .foregroundColor(.white)
                    .padding(16)
                    .background(LinearGradient(colors: [Color.accentBlue, Color.accentBlueActive], startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(16)
                    .shadow(color: Color.accentBlue.opacity(0.3), radius: 8, y: 4)
                }
                .padding(.horizontal, 18)

                // Records
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Records", action: "Add") { showAddRecord = true }
                        .padding(.horizontal, 18)

                    if currentRoom.records.isEmpty {
                        TFCard {
                            HStack {
                                Image(systemName: "note.text").foregroundColor(.textInactive).font(.system(size: 20))
                                Text("No records yet").font(AppFont.medium(14)).foregroundColor(.textSecondary)
                                Spacer()
                            }
                            .padding(16)
                        }
                        .padding(.horizontal, 18)
                    } else {
                        ForEach(currentRoom.records) { record in
                            NavigationLink(destination: RecordDetailView(record: record, projectID: project.id)) {
                                RecordRow(record: record)
                                    .padding(.horizontal, 18)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }

                Spacer().frame(height: 100)
            }
            .padding(.top, 16)
        }
        .background(Color.bgPrimary.ignoresSafeArea())
        .navigationTitle(currentRoom.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showEditRoom = true } label: {
                    Image(systemName: "pencil").foregroundColor(.accentBlue)
                }
            }
        }
        .sheet(isPresented: $showLayoutGenerator) {
            NavigationView {
                LayoutGeneratorView(room: currentRoom, project: project)
            }
        }
        .sheet(isPresented: $showAddRecord) {
            AddRecordView(projectID: project.id, roomID: currentRoom.id)
        }
        .sheet(isPresented: $showEditRoom) {
            EditRoomView(room: currentRoom, projectID: project.id)
        }
    }
}

struct EditRoomView: View {
    @State var room: Room
    let projectID: UUID
    @EnvironmentObject var projectVM: ProjectViewModel
    @Environment(\.presentationMode) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 18) {
                    TFTextField(title: "Room Name", text: $room.name)
                    HStack(spacing: 12) {
                        TFTextField(title: "Width (m)", text: Binding(get: { String(room.widthM) }, set: { room.widthM = Double($0) ?? 0 }), keyboardType: .decimalPad)
                        TFTextField(title: "Length (m)", text: Binding(get: { String(room.lengthM) }, set: { room.lengthM = Double($0) ?? 0 }), keyboardType: .decimalPad)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Status").font(AppFont.medium(13)).foregroundColor(.textSecondary)
                        Picker("", selection: $room.status) {
                            ForEach(ProjectStatus.allCases.filter { $0 != .archived }, id: \.self) {
                                Text($0.label).tag($0)
                            }
                        }.pickerStyle(.segmented)
                    }
                    TFTextField(title: "Notes", text: $room.notes)
                    Button("Save Changes") {
                        projectVM.updateRoom(room, in: projectID)
                        dismiss.wrappedValue.dismiss()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                .padding(.horizontal, 18).padding(.vertical, 16)
            }
            .background(Color.bgPrimary.ignoresSafeArea())
            .navigationTitle("Edit Room").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss.wrappedValue.dismiss() }.foregroundColor(.accentBlue)
                }
            }
        }
    }
}
