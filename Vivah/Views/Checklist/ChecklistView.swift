import SwiftUI

struct ChecklistView: View {
    @EnvironmentObject var store: WeddingStore
    @State private var showAddItem = false
    @State private var searchText = ""
    @State private var selectedPriority: ChecklistItem.Priority? = nil
    @State private var selectedAssignee: FamilySide? = nil
    @State private var selectedEventId: UUID? = nil
    @State private var showCompletedItems = false
    @State private var groupBy: GroupBy = .category

    enum GroupBy: String, CaseIterable {
        case category = "Category"
        case priority = "Priority"
        case assignee = "Assignee"
        case dueDate = "Due Date"
        case event = "Event"
    }

    var filteredItems: [ChecklistItem] {
        var items = store.checklistItems

        if !searchText.isEmpty {
            items = items.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.category.localizedCaseInsensitiveContains(searchText)
            }
        }
        if let priority = selectedPriority {
            items = items.filter { $0.priority == priority }
        }
        if let assignee = selectedAssignee {
            items = items.filter { $0.assignedTo == assignee }
        }
        if let eventId = selectedEventId {
            items = items.filter { $0.eventId == eventId }
        }
        if !showCompletedItems {
            items = items.filter { !$0.isCompleted }
        }
        return items
    }

    var completionPercent: Double {
        guard !store.checklistItems.isEmpty else { return 0 }
        return Double(store.completedChecklistCount) / Double(store.checklistItems.count)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Progress Header
            ChecklistProgressHeader(
                completed: store.completedChecklistCount,
                total: store.checklistItems.count,
                percent: completionPercent,
                overdueCount: store.overdueChecklistItems.count
            )

            // Controls
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                    TextField("Search tasks...", text: $searchText)
                    Toggle("", isOn: $showCompletedItems)
                        .labelsHidden()
                        .tint(VivahTheme.deepRed)
                    Text("Done")
                        .font(.caption).foregroundColor(.secondary)
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(10)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        Menu {
                            ForEach(GroupBy.allCases, id: \.self) { mode in
                                Button(mode.rawValue) { groupBy = mode }
                            }
                        } label: {
                            Label("Group: \(groupBy.rawValue)", systemImage: "line.3.horizontal.decrease.circle")
                                .font(.caption).fontWeight(.medium)
                                .padding(.horizontal, 12).padding(.vertical, 6)
                                .background(VivahTheme.deepRed.opacity(0.1))
                                .foregroundColor(VivahTheme.deepRed)
                                .cornerRadius(16)
                        }

                        ForEach(ChecklistItem.Priority.allCases, id: \.self) { priority in
                            FilterChip(title: priority.rawValue, isSelected: selectedPriority == priority) {
                                selectedPriority = selectedPriority == priority ? nil : priority
                            }
                        }

                        Divider().frame(height: 24)

                        ForEach(FamilySide.allCases, id: \.self) { side in
                            FilterChip(title: side.rawValue.components(separatedBy: "'").first ?? "", isSelected: selectedAssignee == side) {
                                selectedAssignee = selectedAssignee == side ? nil : side
                            }
                        }
                    }
                }
            }
            .padding(12)
            .background(Color(.systemBackground))

            // Checklist
            if filteredItems.isEmpty {
                EmptyStateView(
                    icon: "checkmark.circle",
                    title: showCompletedItems ? "No Tasks Found" : "All Tasks Complete!",
                    subtitle: showCompletedItems ? "Try changing filters" : "Great job staying on top of everything"
                )
            } else {
                ChecklistGroupedView(items: filteredItems, groupBy: groupBy)
                    .environmentObject(store)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Checklist")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAddItem = true }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(VivahTheme.deepRed)
                        .font(.title3)
                }
            }
        }
        .sheet(isPresented: $showAddItem) {
            AddChecklistItemView()
                .environmentObject(store)
        }
    }
}

// MARK: - Progress Header
struct ChecklistProgressHeader: View {
    let completed: Int
    let total: Int
    let percent: Double
    let overdueCount: Int

    var body: some View {
        ZStack {
            Rectangle()
                .fill(VivahTheme.gradient)

            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Wedding Checklist")
                        .font(.caption).foregroundColor(VivahTheme.ivory.opacity(0.7))
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text("\(completed)")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(VivahTheme.gold)
                        Text("/ \(total) done")
                            .font(.subheadline)
                            .foregroundColor(VivahTheme.ivory.opacity(0.8))
                    }
                    if overdueCount > 0 {
                        Label("\(overdueCount) overdue!", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption).foregroundColor(.orange)
                    }
                }

                Spacer()

                ZStack {
                    Circle()
                        .stroke(VivahTheme.ivory.opacity(0.2), lineWidth: 8)
                        .frame(width: 80, height: 80)
                    Circle()
                        .trim(from: 0, to: CGFloat(percent))
                        .stroke(VivahTheme.gold, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 80, height: 80)
                        .animation(.easeInOut(duration: 0.6), value: percent)
                    Text("\(Int(percent * 100))%")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(VivahTheme.gold)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .frame(height: 110)
    }
}

// MARK: - Grouped View
struct ChecklistGroupedView: View {
    @EnvironmentObject var store: WeddingStore
    let items: [ChecklistItem]
    let groupBy: ChecklistView.GroupBy

    var groupedItems: [String: [ChecklistItem]] {
        switch groupBy {
        case .category:
            return Dictionary(grouping: items) { $0.category.isEmpty ? "General" : $0.category }
        case .priority:
            return Dictionary(grouping: items) { $0.priority.rawValue }
        case .assignee:
            return Dictionary(grouping: items) { $0.assignedTo.rawValue }
        case .dueDate:
            return Dictionary(grouping: items) { item -> String in
                guard let due = item.dueDate else { return "No Due Date" }
                let days = Calendar.current.dateComponents([.day], from: Date(), to: due).day ?? 0
                if days < 0 { return "Overdue" }
                if days == 0 { return "Today" }
                if days <= 7 { return "This Week" }
                if days <= 30 { return "This Month" }
                return "Later"
            }
        case .event:
            return Dictionary(grouping: items) { item -> String in
                if let eid = item.eventId, let event = store.events.first(where: { $0.id == eid }) {
                    return event.name
                }
                return "General"
            }
        }
    }

    var sortedKeys: [String] {
        let keys = groupedItems.keys.sorted()
        if groupBy == .priority {
            let order = ["Urgent", "High", "Medium", "Low"]
            return order.filter { keys.contains($0) } + keys.filter { !order.contains($0) }
        }
        if groupBy == .dueDate {
            let order = ["Overdue", "Today", "This Week", "This Month", "Later", "No Due Date"]
            return order.filter { keys.contains($0) } + keys.filter { !order.contains($0) }
        }
        return keys
    }

    var body: some View {
        List {
            ForEach(sortedKeys, id: \.self) { key in
                let sectionItems = groupedItems[key] ?? []
                let completedCount = sectionItems.filter { $0.isCompleted }.count

                Section {
                    ForEach(sectionItems) { item in
                        ChecklistRow(item: item)
                            .environmentObject(store)
                    }
                    .onDelete { offsets in
                        offsets.forEach { i in
                            store.deleteChecklistItem(sectionItems[i])
                        }
                    }
                } header: {
                    HStack {
                        Text(key)
                        Spacer()
                        Text("\(completedCount)/\(sectionItems.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - Checklist Row
struct ChecklistRow: View {
    @EnvironmentObject var store: WeddingStore
    let item: ChecklistItem
    @State private var showDetail = false

    var isOverdue: Bool {
        !item.isCompleted && item.dueDate != nil && item.dueDate! < Date()
    }

    var body: some View {
        HStack(spacing: 12) {
            Button(action: { store.toggleChecklistItem(item) }) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(item.isCompleted ? .green : .secondary)
            }
            .buttonStyle(PlainButtonStyle())

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(item.title)
                        .font(.subheadline)
                        .strikethrough(item.isCompleted)
                        .foregroundColor(item.isCompleted ? .secondary : .primary)
                        .lineLimit(2)
                    if item.priority == .urgent || item.priority == .high {
                        Circle()
                            .fill(item.priority.color)
                            .frame(width: 7, height: 7)
                    }
                }

                HStack(spacing: 6) {
                    if let due = item.dueDate {
                        HStack(spacing: 3) {
                            Image(systemName: "calendar")
                                .font(.caption2)
                            Text(due, style: .date)
                                .font(.caption2)
                        }
                        .foregroundColor(isOverdue ? .red : .secondary)
                    }
                    if !item.category.isEmpty {
                        Text("•")
                            .font(.caption2).foregroundColor(.secondary)
                        Text(item.category)
                            .font(.caption2).foregroundColor(.secondary)
                    }
                    Text("•")
                        .font(.caption2).foregroundColor(.secondary)
                    Text(item.assignedTo.rawValue.components(separatedBy: "'").first ?? "")
                        .font(.caption2).foregroundColor(.secondary)
                }
            }

            Spacer()

            if isOverdue {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture { showDetail = true }
        .sheet(isPresented: $showDetail) {
            ChecklistItemDetailView(item: item)
                .environmentObject(store)
        }
    }
}

// MARK: - Checklist Item Detail
struct ChecklistItemDetailView: View {
    @EnvironmentObject var store: WeddingStore
    @Environment(\.dismiss) var dismiss
    @State var item: ChecklistItem

    init(item: ChecklistItem) {
        _item = State(initialValue: item)
    }

    var eventName: String {
        if let eid = item.eventId, let event = store.events.first(where: { $0.id == eid }) {
            return event.name
        }
        return "General"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Task") {
                    TextField("Title", text: $item.title, axis: .vertical)
                        .lineLimit(2...4)
                    TextField("Description", text: $item.description, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section("Details") {
                    Picker("Priority", selection: $item.priority) {
                        ForEach(ChecklistItem.Priority.allCases, id: \.self) { p in
                            HStack {
                                Circle().fill(p.color).frame(width: 10, height: 10)
                                Text(p.rawValue)
                            }.tag(p)
                        }
                    }
                    Picker("Assigned To", selection: $item.assignedTo) {
                        ForEach(FamilySide.allCases, id: \.self) { side in
                            Text(side.rawValue).tag(side)
                        }
                    }
                    TextField("Category", text: $item.category)
                    Picker("Event", selection: $item.eventId) {
                        Text("General").tag(nil as UUID?)
                        ForEach(store.events) { event in
                            Text(event.name).tag(event.id as UUID?)
                        }
                    }
                }

                Section("Due Date") {
                    Toggle("Has Due Date", isOn: Binding(
                        get: { item.dueDate != nil },
                        set: { if $0 { item.dueDate = Date() } else { item.dueDate = nil } }
                    ))
                    if item.dueDate != nil {
                        DatePicker("Due Date", selection: Binding(
                            get: { item.dueDate ?? Date() },
                            set: { item.dueDate = $0 }
                        ), displayedComponents: .date)
                    }
                }

                Section("Completion") {
                    Toggle("Completed", isOn: $item.isCompleted)
                        .onChange(of: item.isCompleted) { completed in
                            item.completedDate = completed ? Date() : nil
                        }
                    if let cd = item.completedDate {
                        DetailRow(label: "Completed On", value: cd.formatted(date: .medium, time: .omitted))
                    }
                }

                Section("Notes") {
                    TextField("Notes...", text: $item.notes, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section {
                    Button("Delete Task", role: .destructive) {
                        store.deleteChecklistItem(item)
                        dismiss()
                    }
                }
            }
            .navigationTitle("Task Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.updateChecklistItem(item)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Add Checklist Item
struct AddChecklistItemView: View {
    @EnvironmentObject var store: WeddingStore
    @Environment(\.dismiss) var dismiss

    @State private var title = ""
    @State private var description = ""
    @State private var category = "General"
    @State private var priority: ChecklistItem.Priority = .medium
    @State private var assignedTo: FamilySide = .shared
    @State private var hasDueDate = true
    @State private var dueDate = Date().addingTimeInterval(7 * 86400)
    @State private var eventId: UUID? = nil
    @State private var notes = ""

    let categories = ["General", "Ceremony", "Venue", "Catering", "Clothing", "Jewellery",
                      "Photography", "Invitations", "Travel", "Beauty", "Rituals", "Legal"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Task") {
                    TextField("Task Title", text: $title)
                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section("Categorize") {
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                    Picker("Priority", selection: $priority) {
                        ForEach(ChecklistItem.Priority.allCases, id: \.self) { p in
                            Text(p.rawValue).tag(p)
                        }
                    }
                    Picker("Assigned To", selection: $assignedTo) {
                        ForEach(FamilySide.allCases, id: \.self) { side in
                            Text(side.rawValue).tag(side)
                        }
                    }
                    Picker("Event (Optional)", selection: $eventId) {
                        Text("General").tag(nil as UUID?)
                        ForEach(store.events) { event in
                            Text(event.name).tag(event.id as UUID?)
                        }
                    }
                }

                Section("Due Date") {
                    Toggle("Set Due Date", isOn: $hasDueDate)
                    if hasDueDate {
                        DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                    }
                }

                Section("Notes") {
                    TextField("Any notes...", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }

                // Quick-add from templates
                Section("Quick Add from Template") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(store.wedding.religion.defaultChecklist.prefix(6), id: \.self) { task in
                                Button(task) { title = task; category = "Ceremony" }
                                    .font(.caption)
                                    .padding(.horizontal, 10).padding(.vertical, 5)
                                    .background(title == task ? VivahTheme.deepRed : Color(.systemGray5))
                                    .foregroundColor(title == task ? .white : .primary)
                                    .cornerRadius(14)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Add Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { saveItem() }
                        .disabled(title.isEmpty)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    func saveItem() {
        var item = ChecklistItem(title: title)
        item.description = description
        item.category = category
        item.priority = priority
        item.assignedTo = assignedTo
        item.dueDate = hasDueDate ? dueDate : nil
        item.eventId = eventId
        item.notes = notes
        store.addChecklistItem(item)
        dismiss()
    }
}
