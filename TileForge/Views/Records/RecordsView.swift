import SwiftUI

// MARK: - Record Row
struct RecordRow: View {
    let record: Record
    var body: some View {
        TFCard {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(record.category.color.opacity(0.15)).frame(width: 38, height: 38)
                    Image(systemName: record.category.icon).foregroundColor(record.category.color).font(.system(size: 15, weight: .semibold))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(record.title).font(AppFont.semibold(14)).foregroundColor(.textPrimary)
                    HStack(spacing: 6) {
                        Text(record.category.rawValue).font(AppFont.regular(12)).foregroundColor(.textSecondary)
                        if !record.value.isEmpty {
                            Text("· \(record.value)").font(AppFont.regular(12)).foregroundColor(.textSecondary)
                        }
                    }
                    Text(record.date, style: .date).font(AppFont.regular(11)).foregroundColor(.textInactive)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundColor(.textInactive).font(.system(size: 12))
            }
            .padding(12)
        }
    }
}

// MARK: - Record Detail
struct RecordDetailView: View {
    let record: Record
    let projectID: UUID
    @EnvironmentObject var projectVM: ProjectViewModel
    @Environment(\.presentationMode) var dismiss
    @State private var showEdit = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                TFCard {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            ZStack {
                                Circle().fill(record.category.color.opacity(0.15)).frame(width: 48, height: 48)
                                Image(systemName: record.category.icon).foregroundColor(record.category.color).font(.system(size: 20, weight: .semibold))
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(record.title).font(AppFont.bold(20)).foregroundColor(.textPrimary)
                                Text(record.category.rawValue).font(AppFont.regular(13)).foregroundColor(.textSecondary)
                            }
                            Spacer()
                            StatusBadge(status: record.status)
                        }
                        Divider()
                        if !record.value.isEmpty {
                            HStack { Text("Value:").font(AppFont.medium(14)).foregroundColor(.textSecondary); Spacer(); Text(record.value).font(AppFont.semibold(14)).foregroundColor(.textPrimary) }
                        }
                        HStack { Text("Date:").font(AppFont.medium(14)).foregroundColor(.textSecondary); Spacer(); Text(record.date, style: .date).font(AppFont.regular(14)).foregroundColor(.textPrimary) }
                        if !record.comment.isEmpty {
                            Divider()
                            Text(record.comment).font(AppFont.regular(14)).foregroundColor(.textPrimary).fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(16)
                }
                .padding(.horizontal, 18)

                HStack(spacing: 12) {
                    Button("Edit") { showEdit = true }.buttonStyle(SecondaryButtonStyle())
                    Button("Duplicate") {
                        var copy = record
                        copy.id = UUID()
                        copy.createdAt = Date()
                        projectVM.addRecord(copy, to: projectID)
                        dismiss.wrappedValue.dismiss()
                    }.buttonStyle(PrimaryButtonStyle())
                }
                .padding(.horizontal, 18)

                Button(role: .destructive) {
                    projectVM.deleteRecord(record.id, from: projectID)
                    dismiss.wrappedValue.dismiss()
                } label: {
                    HStack { Image(systemName: "trash"); Text("Delete Record") }
                        .font(AppFont.medium(14)).foregroundColor(.statusError)
                }
                .padding(.top, 4)

                Spacer().frame(height: 100)
            }
            .padding(.top, 16)
        }
        .background(Color.bgPrimary.ignoresSafeArea())
        .navigationTitle("Record Detail")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEdit) {
            AddRecordView(projectID: projectID, roomID: record.roomID, existingRecord: record)
        }
    }
}

// MARK: - Add Record
struct AddRecordView: View {
    let projectID: UUID
    var roomID: UUID? = nil
    var existingRecord: Record? = nil
    @EnvironmentObject var projectVM: ProjectViewModel
    @Environment(\.presentationMode) var dismiss

    @State private var title = ""
    @State private var category = RecordCategory.note
    @State private var value = ""
    @State private var comment = ""
    @State private var date = Date()
    @State private var showValidation = false
    @State private var addAnother = false

    var isEditing: Bool { existingRecord != nil }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 18) {
                    TFTextField(title: "Title", text: $title, placeholder: "e.g. Floor measurement")
                    if showValidation && title.isEmpty {
                        Text("Title is required").font(AppFont.regular(12)).foregroundColor(.statusError).frame(maxWidth: .infinity, alignment: .leading)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Category").font(AppFont.medium(13)).foregroundColor(.textSecondary)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(RecordCategory.allCases, id: \.self) { cat in
                                    Button { withAnimation { category = cat } } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: cat.icon).font(.system(size: 12, weight: .semibold))
                                            Text(cat.rawValue).font(AppFont.medium(13))
                                        }
                                        .foregroundColor(category == cat ? .white : .textPrimary)
                                        .padding(.horizontal, 12).padding(.vertical, 8)
                                        .background(category == cat ? cat.color : Color.cardWhite)
                                        .cornerRadius(10)
                                    }
                                }
                            }
                        }
                    }

                    TFTextField(title: "Value", text: $value, placeholder: "e.g. 12.5 m² or €280")

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Date").font(AppFont.medium(13)).foregroundColor(.textSecondary)
                        DatePicker("", selection: $date, displayedComponents: .date).datePickerStyle(.compact).labelsHidden()
                            .padding(12).background(Color.bgSecondary).cornerRadius(12)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Comment").font(AppFont.medium(13)).foregroundColor(.textSecondary)
                        TextEditor(text: $comment).font(AppFont.regular(15)).frame(height: 80)
                            .padding(10).background(Color.bgSecondary).cornerRadius(12)
                    }

                    Button(isEditing ? "Save Changes" : "Save Record") {
                        if title.isEmpty { showValidation = true; return }
                        if isEditing {
                            // Update existing
                            if let pIdx = projectVM.projects.firstIndex(where: { $0.id == projectID }) {
                                for rIdx in projectVM.projects[pIdx].rooms.indices {
                                    if let recIdx = projectVM.projects[pIdx].rooms[rIdx].records.firstIndex(where: { $0.id == existingRecord!.id }) {
                                        projectVM.projects[pIdx].rooms[rIdx].records[recIdx].title = title
                                        projectVM.projects[pIdx].rooms[rIdx].records[recIdx].category = category
                                        projectVM.projects[pIdx].rooms[rIdx].records[recIdx].value = value
                                        projectVM.projects[pIdx].rooms[rIdx].records[recIdx].comment = comment
                                        projectVM.save()
                                    }
                                }
                            }
                        } else {
                            var record = Record(title: title, roomID: roomID, date: date, category: category, value: value, comment: comment)
                            projectVM.addRecord(record, to: projectID)
                            if addAnother { title = ""; value = ""; comment = ""; return }
                        }
                        dismiss.wrappedValue.dismiss()
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    if !isEditing {
                        Toggle("Add Another", isOn: $addAnother).font(AppFont.medium(14)).foregroundColor(.textSecondary)
                    }
                }
                .padding(.horizontal, 18).padding(.vertical, 16)
            }
            .background(Color.bgPrimary.ignoresSafeArea())
            .navigationTitle(isEditing ? "Edit Record" : "Add Record").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss.wrappedValue.dismiss() }.foregroundColor(.accentBlue)
                }
            }
            .onAppear {
                if let r = existingRecord {
                    title = r.title; category = r.category; value = r.value; comment = r.comment; date = r.date
                }
            }
        }
    }
}

// MARK: - Tasks View
struct TasksView: View {
    @EnvironmentObject var projectVM: ProjectViewModel
    @State private var filter = "All"
    @State private var showAddTask = false

    let filters = ["All", "Today", "Overdue", "Done"]

    var filteredTasks: [TFTask] {
        switch filter {
        case "Today": return projectVM.todayTasks
        case "Overdue": return projectVM.overdueTasks
        case "Done": return projectVM.doneTasks
        default: return projectVM.tasks
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter tabs
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(filters, id: \.self) { f in
                            Button { withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { filter = f } } label: {
                                HStack(spacing: 4) {
                                    Text(f).font(AppFont.semibold(13))
                                        .foregroundColor(filter == f ? .white : .textSecondary)
                                    if f == "Overdue" && !projectVM.overdueTasks.isEmpty {
                                        Text("\(projectVM.overdueTasks.count)")
                                            .font(AppFont.bold(11)).foregroundColor(filter == f ? .white : .statusError)
                                            .padding(.horizontal, 5).padding(.vertical, 1)
                                            .background(filter == f ? Color.white.opacity(0.3) : Color.statusError.opacity(0.15))
                                            .cornerRadius(6)
                                    }
                                }
                                .padding(.horizontal, 14).padding(.vertical, 7)
                                .background(filter == f ? Color.accentBlue : Color.cardWhite)
                                .cornerRadius(10)
                                .shadow(color: Color.black.opacity(0.04), radius: 4, y: 2)
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                }
                .padding(.vertical, 10)

                if filteredTasks.isEmpty {
                    Spacer()
                    EmptyStateView(icon: "checkmark.circle", title: "No Tasks", subtitle: "Add tasks to track your project progress.", action: "Add Task") { showAddTask = true }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(filteredTasks) { task in
                                TaskDetailRow(task: task)
                                    .padding(.horizontal, 18)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) { projectVM.deleteTask(task) } label: { Label("Delete", systemImage: "trash") }
                                    }
                                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                        Button { projectVM.toggleTaskDone(task.id) } label: { Label("Done", systemImage: "checkmark") }.tint(.statusDone)
                                    }
                            }
                        }
                        .padding(.vertical, 8).padding(.bottom, 100)
                    }
                }
            }
            .background(Color.bgPrimary.ignoresSafeArea())
            .navigationTitle("Tasks")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showAddTask = true } label: { Image(systemName: "plus").foregroundColor(.accentBlue) }
                }
            }
        }
        .navigationViewStyle(.stack)
        .sheet(isPresented: $showAddTask) { AddTaskView() }
    }
}

struct TaskDetailRow: View {
    let task: TFTask
    @EnvironmentObject var projectVM: ProjectViewModel
    @State private var showEdit = false

    var body: some View {
        TFCard {
            HStack(spacing: 12) {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { projectVM.toggleTaskDone(task.id) }
                } label: {
                    Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 24))
                        .foregroundColor(task.isDone ? .statusDone : .textInactive)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(AppFont.semibold(15)).foregroundColor(.textPrimary)
                        .strikethrough(task.isDone, color: .textInactive)
                    HStack(spacing: 8) {
                        if let due = task.dueDate {
                            Text(due, format: .dateTime.month().day())
                                .font(AppFont.regular(12))
                                .foregroundColor(task.isOverdue ? .statusError : .textSecondary)
                        }
                        Circle().fill(task.priority.color).frame(width: 6, height: 6)
                        Text(task.priority.rawValue).font(AppFont.regular(12)).foregroundColor(.textSecondary)
                    }
                    if !task.notes.isEmpty {
                        Text(task.notes).font(AppFont.regular(12)).foregroundColor(.textInactive).lineLimit(1)
                    }
                }
                Spacer()
                Button { showEdit = true } label: {
                    Image(systemName: "pencil.circle").foregroundColor(.textInactive).font(.system(size: 20))
                }
            }
            .padding(14)
        }
        .sheet(isPresented: $showEdit) { EditTaskView(task: task) }
    }
}

// MARK: - Add Task
struct AddTaskView: View {
    @EnvironmentObject var projectVM: ProjectViewModel
    @Environment(\.presentationMode) var dismiss
    @State private var title = ""
    @State private var priority = TaskPriority.medium
    @State private var notes = ""
    @State private var hasDueDate = false
    @State private var dueDate = Date()
    @State private var showValidation = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 18) {
                    TFTextField(title: "Task Title", text: $title, placeholder: "e.g. Order bathroom tiles")
                    if showValidation && title.isEmpty {
                        Text("Task title is required").font(AppFont.regular(12)).foregroundColor(.statusError).frame(maxWidth: .infinity, alignment: .leading)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Priority").font(AppFont.medium(13)).foregroundColor(.textSecondary)
                        HStack(spacing: 10) {
                            ForEach(TaskPriority.allCases, id: \.self) { p in
                                Button { withAnimation { priority = p } } label: {
                                    HStack(spacing: 4) {
                                        Circle().fill(p.color).frame(width: 8, height: 8)
                                        Text(p.rawValue).font(AppFont.semibold(13))
                                    }
                                    .foregroundColor(priority == p ? .white : .textPrimary)
                                    .padding(.horizontal, 14).padding(.vertical, 9)
                                    .background(priority == p ? p.color : Color.cardWhite)
                                    .cornerRadius(10)
                                }
                            }
                        }
                    }

                    Toggle("Set Due Date", isOn: $hasDueDate.animation())
                        .font(AppFont.medium(14)).foregroundColor(.textPrimary)
                    if hasDueDate {
                        DatePicker("Due Date", selection: $dueDate, in: Date()..., displayedComponents: .date)
                            .datePickerStyle(.graphical).accentColor(.accentBlue)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Notes").font(AppFont.medium(13)).foregroundColor(.textSecondary)
                        TextEditor(text: $notes).font(AppFont.regular(15)).frame(height: 80)
                            .padding(10).background(Color.bgSecondary).cornerRadius(12)
                    }

                    Button("Add Task") {
                        if title.isEmpty { showValidation = true; return }
                        let task = TFTask(title: title, dueDate: hasDueDate ? dueDate : nil, priority: priority, notes: notes)
                        projectVM.addTask(task)
                        dismiss.wrappedValue.dismiss()
                    }.buttonStyle(PrimaryButtonStyle())
                }
                .padding(.horizontal, 18).padding(.vertical, 16)
            }
            .background(Color.bgPrimary.ignoresSafeArea())
            .navigationTitle("Add Task").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss.wrappedValue.dismiss() }.foregroundColor(.accentBlue) } }
        }
    }
}

struct EditTaskView: View {
    @State var task: TFTask
    @EnvironmentObject var projectVM: ProjectViewModel
    @Environment(\.presentationMode) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 18) {
                    TFTextField(title: "Title", text: $task.title)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Priority").font(AppFont.medium(13)).foregroundColor(.textSecondary)
                        HStack(spacing: 10) {
                            ForEach(TaskPriority.allCases, id: \.self) { p in
                                Button { task.priority = p } label: {
                                    HStack(spacing: 4) { Circle().fill(p.color).frame(width: 8, height: 8); Text(p.rawValue).font(AppFont.semibold(13)) }
                                        .foregroundColor(task.priority == p ? .white : .textPrimary)
                                        .padding(.horizontal, 14).padding(.vertical, 9)
                                        .background(task.priority == p ? p.color : Color.cardWhite).cornerRadius(10)
                                }
                            }
                        }
                    }
                    TFTextField(title: "Notes", text: $task.notes)
                    Button("Save Changes") { projectVM.updateTask(task); dismiss.wrappedValue.dismiss() }.buttonStyle(PrimaryButtonStyle())
                }
                .padding(.horizontal, 18).padding(.vertical, 16)
            }
            .background(Color.bgPrimary.ignoresSafeArea())
            .navigationTitle("Edit Task").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss.wrappedValue.dismiss() }.foregroundColor(.accentBlue) } }
        }
    }
}
