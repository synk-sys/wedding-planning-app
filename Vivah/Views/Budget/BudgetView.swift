import SwiftUI

struct BudgetView: View {
    @EnvironmentObject var store: WeddingStore
    @State private var showAddItem = false
    @State private var selectedView: BudgetViewMode = .overview
    @State private var selectedEventFilter: UUID? = nil
    @State private var selectedFamilyFilter: FamilySide? = nil

    enum BudgetViewMode: String, CaseIterable {
        case overview = "Overview"
        case byEvent = "By Event"
        case byFamily = "By Family"
        case categories = "Categories"
    }

    var filteredItems: [BudgetItem] {
        var items = store.budgetItems
        if let eventId = selectedEventFilter {
            items = items.filter { $0.eventId == eventId }
        }
        if let family = selectedFamilyFilter {
            items = items.filter { $0.paidBy == family }
        }
        return items
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // View mode picker
                Picker("View", selection: $selectedView) {
                    ForEach(BudgetViewMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(12)
                .background(Color(.systemBackground))

                ScrollView {
                    VStack(spacing: 16) {
                        switch selectedView {
                        case .overview:
                            BudgetOverviewSection()
                                .environmentObject(store)
                            BudgetItemsList(items: store.budgetItems, showAddItem: $showAddItem)
                                .environmentObject(store)
                        case .byEvent:
                            BudgetByEventSection(showAddItem: $showAddItem)
                                .environmentObject(store)
                        case .byFamily:
                            BudgetByFamilySection()
                                .environmentObject(store)
                        case .categories:
                            BudgetByCategorySection()
                                .environmentObject(store)
                        }
                    }
                    .padding(16)
                    .padding(.bottom, 20)
                }
                .background(Color(.systemGroupedBackground))
            }
            .navigationTitle("Budget")
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
                AddBudgetItemView()
                    .environmentObject(store)
            }
        }
    }
}

// MARK: - Budget Overview Section
struct BudgetOverviewSection: View {
    @EnvironmentObject var store: WeddingStore

    var spentPercent: Double {
        guard store.wedding.totalBudget > 0 else { return 0 }
        return min(store.totalBudgetSpent / store.wedding.totalBudget, 1.0)
    }

    var body: some View {
        VStack(spacing: 14) {
            // Main Budget Donut-style card
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(VivahTheme.gradient)
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Total Budget")
                                .font(.caption).foregroundColor(VivahTheme.ivory.opacity(0.7))
                            Text(store.wedding.totalBudget.inrFormatted)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(VivahTheme.gold)
                        }
                        Spacer()
                        CircularProgressView(progress: spentPercent, color: VivahTheme.gold)
                            .frame(width: 64, height: 64)
                    }

                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(VivahTheme.ivory.opacity(0.2))
                                .frame(height: 10)
                            RoundedRectangle(cornerRadius: 6)
                                .fill(spentPercent > 0.9 ? Color.red : VivahTheme.gold)
                                .frame(width: geo.size.width * CGFloat(spentPercent), height: 10)
                        }
                    }
                    .frame(height: 10)

                    HStack(spacing: 20) {
                        BudgetStatCell(label: "Spent", value: store.totalBudgetSpent.inrShortFormatted, color: VivahTheme.roseGold)
                        BudgetStatCell(label: "Paid", value: store.totalPaid.inrShortFormatted, color: VivahTheme.gold)
                        BudgetStatCell(label: "Remaining", value: store.budgetRemaining.inrShortFormatted, color: VivahTheme.ivory)
                        BudgetStatCell(label: "Items", value: "\(store.budgetItems.count)", color: VivahTheme.ivory.opacity(0.7))
                    }
                }
                .padding(20)
            }
            .shadow(color: VivahTheme.deepRed.opacity(0.3), radius: 10, x: 0, y: 4)

            // Family split card
            VStack(alignment: .leading, spacing: 14) {
                Label("Family Budget Split", systemImage: "person.2.fill")
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundColor(VivahTheme.deepRed)

                HStack(spacing: 12) {
                    FamilySplitCard(
                        name: "Bride's Family",
                        spent: store.brideFamilySpend,
                        budgetShare: store.wedding.totalBudget * store.wedding.brideFamilyBudgetShare / 100,
                        color: VivahTheme.deepRed
                    )
                    FamilySplitCard(
                        name: "Groom's Family",
                        spent: store.groomFamilySpend,
                        budgetShare: store.wedding.totalBudget * store.wedding.groomFamilyBudgetShare / 100,
                        color: VivahTheme.gold
                    )
                }

                // Shared
                HStack {
                    Label("Shared Expenses", systemImage: "equal.circle")
                        .font(.caption).foregroundColor(.secondary)
                    Spacer()
                    Text(store.budgetItems.filter { $0.paidBy == .shared }.reduce(0) { $0 + $1.paidAmount }.inrShortFormatted)
                        .font(.subheadline).fontWeight(.semibold)
                }
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
        }
    }
}

struct BudgetStatCell: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(color.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
    }
}

struct FamilySplitCard: View {
    let name: String
    let spent: Double
    let budgetShare: Double
    let color: Color

    var percent: Double {
        guard budgetShare > 0 else { return 0 }
        return min(spent / budgetShare, 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(name)
                .font(.caption).fontWeight(.medium).foregroundColor(.secondary)
            Text(spent.inrShortFormatted)
                .font(.title3).fontWeight(.bold).foregroundColor(color)
            Text("of \(budgetShare.inrShortFormatted)")
                .font(.caption2).foregroundColor(.secondary)
            ProgressView(value: percent)
                .tint(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(color.opacity(0.08))
        .cornerRadius(12)
    }
}

struct CircularProgressView: View {
    let progress: Double
    let color: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 6)
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.6), value: progress)
            Text("\(Int(progress * 100))%")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(color)
        }
    }
}

// MARK: - Budget Items List
struct BudgetItemsList: View {
    @EnvironmentObject var store: WeddingStore
    let items: [BudgetItem]
    @Binding var showAddItem: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Budget Items", systemImage: "list.bullet.rectangle")
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundColor(VivahTheme.deepRed)
                Spacer()
                Button(action: { showAddItem = true }) {
                    Image(systemName: "plus")
                        .foregroundColor(VivahTheme.deepRed)
                }
            }

            if items.isEmpty {
                Text("No budget items yet. Tap + to add one.")
                    .font(.subheadline).foregroundColor(.secondary)
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity)
            } else {
                ForEach(items) { item in
                    BudgetItemRow(item: item)
                        .environmentObject(store)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
    }
}

struct BudgetItemRow: View {
    @EnvironmentObject var store: WeddingStore
    let item: BudgetItem
    @State private var showEdit = false

    var eventName: String {
        if let eid = item.eventId, let event = store.events.first(where: { $0.id == eid }) {
            return event.name
        }
        return "General"
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(familyColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: categoryIcon(item.category))
                    .font(.caption)
                    .foregroundColor(familyColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.subheadline).fontWeight(.medium)
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Text(eventName)
                        .font(.caption2).foregroundColor(.secondary)
                    Text("•")
                    Text(item.paidBy.rawValue)
                        .font(.caption2).foregroundColor(familyColor)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(item.actualAmount > 0 ? item.actualAmount.inrShortFormatted : item.estimatedAmount.inrShortFormatted)
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundColor(item.actualAmount > 0 ? .primary : .secondary)
                HStack(spacing: 4) {
                    if item.paidAmount > 0 {
                        Text("Paid: \(item.paidAmount.inrShortFormatted)")
                            .font(.caption2).foregroundColor(.green)
                    } else {
                        Text("Unpaid")
                            .font(.caption2).foregroundColor(.orange)
                    }
                }
            }
        }
        .padding(.vertical, 6)
        .onTapGesture { showEdit = true }
        .sheet(isPresented: $showEdit) {
            EditBudgetItemView(item: item)
                .environmentObject(store)
        }
    }

    var familyColor: Color {
        switch item.paidBy {
        case .bride: return VivahTheme.deepRed
        case .groom: return VivahTheme.gold
        case .shared: return VivahTheme.forestGreen
        }
    }

    func categoryIcon(_ cat: BudgetCategory) -> String {
        switch cat {
        case .venue: return "building.2"
        case .catering: return "fork.knife"
        case .decoration: return "sparkles"
        case .photography: return "camera"
        case .music: return "music.note"
        case .clothing: return "tag"
        case .jewellery: return "star"
        case .makeup: return "paintbrush"
        case .invitations: return "envelope"
        case .transport: return "car"
        case .accommodation: return "bed.double"
        case .miscellaneous: return "ellipsis.circle"
        }
    }
}

// MARK: - Budget By Event Section
struct BudgetByEventSection: View {
    @EnvironmentObject var store: WeddingStore
    @Binding var showAddItem: Bool

    var body: some View {
        VStack(spacing: 14) {
            ForEach(store.events) { event in
                let items = store.budgetItemsForEvent(event.id)
                let total = store.totalSpendForEvent(event.id)

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(event.name)
                                .font(.headline)
                            Text(event.date, style: .date)
                                .font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        Text(total.inrShortFormatted)
                            .font(.title3).fontWeight(.bold)
                            .foregroundColor(VivahTheme.deepRed)
                    }

                    if items.isEmpty {
                        Text("No budget items")
                            .font(.caption).foregroundColor(.secondary)
                    } else {
                        ForEach(items.prefix(3)) { item in
                            HStack {
                                Text(item.title)
                                    .font(.caption)
                                Spacer()
                                Text(item.actualAmount.inrShortFormatted)
                                    .font(.caption).fontWeight(.medium)
                            }
                            .foregroundColor(.secondary)
                        }
                        if items.count > 3 {
                            Text("+ \(items.count - 3) more items")
                                .font(.caption2).foregroundColor(VivahTheme.gold)
                        }
                    }
                }
                .padding(14)
                .background(Color(.systemBackground))
                .cornerRadius(14)
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 1)
            }

            // Unassigned items
            let unassigned = store.budgetItems.filter { $0.eventId == nil }
            if !unassigned.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("General / Unassigned")
                        .font(.headline)
                    ForEach(unassigned.prefix(3)) { item in
                        HStack {
                            Text(item.title).font(.caption)
                            Spacer()
                            Text(item.actualAmount.inrShortFormatted).font(.caption).fontWeight(.medium)
                        }
                        .foregroundColor(.secondary)
                    }
                }
                .padding(14)
                .background(Color(.systemBackground))
                .cornerRadius(14)
            }
        }
    }
}

// MARK: - Budget By Family Section
struct BudgetByFamilySection: View {
    @EnvironmentObject var store: WeddingStore

    var body: some View {
        VStack(spacing: 14) {
            ForEach(FamilySide.allCases, id: \.self) { side in
                let items = store.budgetItems.filter { $0.paidBy == side }
                let total = items.reduce(0) { $0 + $1.paidAmount }

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Label(side.rawValue, systemImage: side == .bride ? "person.fill" : side == .groom ? "person.fill" : "equal.circle")
                            .font(.headline)
                            .foregroundColor(sideColor(side))
                        Spacer()
                        Text(total.inrShortFormatted)
                            .font(.title3).fontWeight(.bold)
                            .foregroundColor(sideColor(side))
                    }

                    if items.isEmpty {
                        Text("No items assigned")
                            .font(.caption).foregroundColor(.secondary)
                    } else {
                        ForEach(items) { item in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(item.title).font(.subheadline).fontWeight(.medium)
                                    Text(item.category.rawValue).font(.caption2).foregroundColor(.secondary)
                                }
                                Spacer()
                                VStack(alignment: .trailing) {
                                    Text(item.paidAmount.inrShortFormatted)
                                        .font(.subheadline).fontWeight(.semibold)
                                    Text("of \(item.estimatedAmount.inrShortFormatted)")
                                        .font(.caption2).foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
                .padding(14)
                .background(Color(.systemBackground))
                .cornerRadius(14)
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 1)
            }
        }
    }

    func sideColor(_ side: FamilySide) -> Color {
        switch side {
        case .bride: return VivahTheme.deepRed
        case .groom: return VivahTheme.gold
        case .shared: return VivahTheme.forestGreen
        }
    }
}

// MARK: - Budget By Category Section
struct BudgetByCategorySection: View {
    @EnvironmentObject var store: WeddingStore

    var categoryTotals: [(BudgetCategory, Double)] {
        BudgetCategory.allCases.compactMap { cat in
            let total = store.budgetItems.filter { $0.category == cat }.reduce(0) { $0 + $1.actualAmount }
            return total > 0 ? (cat, total) : nil
        }.sorted { $0.1 > $1.1 }
    }

    var maxAmount: Double {
        categoryTotals.first?.1 ?? 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Spending by Category", systemImage: "chart.bar.fill")
                .font(.subheadline).fontWeight(.semibold)
                .foregroundColor(VivahTheme.deepRed)

            if categoryTotals.isEmpty {
                Text("No spending data yet.")
                    .font(.subheadline).foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(categoryTotals, id: \.0) { cat, amount in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(cat.rawValue)
                                .font(.subheadline).fontWeight(.medium)
                            Spacer()
                            Text(amount.inrShortFormatted)
                                .font(.subheadline).fontWeight(.semibold)
                                .foregroundColor(VivahTheme.deepRed)
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(.systemGray5))
                                    .frame(height: 8)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(VivahTheme.goldGradient)
                                    .frame(width: geo.size.width * CGFloat(amount / maxAmount), height: 8)
                            }
                        }
                        .frame(height: 8)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Add Budget Item
struct AddBudgetItemView: View {
    @EnvironmentObject var store: WeddingStore
    @Environment(\.dismiss) var dismiss

    @State private var title = ""
    @State private var category: BudgetCategory = .venue
    @State private var eventId: UUID? = nil
    @State private var estimatedAmount = ""
    @State private var actualAmount = ""
    @State private var paidAmount = ""
    @State private var paidBy: FamilySide = .shared
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Item Details") {
                    TextField("Item Name (e.g. Catering for Sangeet)", text: $title)
                    Picker("Category", selection: $category) {
                        ForEach(BudgetCategory.allCases, id: \.self) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }
                    Picker("Event", selection: $eventId) {
                        Text("General").tag(nil as UUID?)
                        ForEach(store.events) { event in
                            Text(event.name).tag(event.id as UUID?)
                        }
                    }
                }
                Section("Amounts (₹)") {
                    HStack {
                        Text("Estimated")
                        Spacer()
                        TextField("0", text: $estimatedAmount)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Actual")
                        Spacer()
                        TextField("0", text: $actualAmount)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Paid So Far")
                        Spacer()
                        TextField("0", text: $paidAmount)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                Section("Responsibility") {
                    Picker("Paid By", selection: $paidBy) {
                        ForEach(FamilySide.allCases, id: \.self) { side in
                            Text(side.rawValue).tag(side)
                        }
                    }
                }
                Section("Notes") {
                    TextField("Notes...", text: $notes, axis: .vertical)
                        .lineLimit(3...5)
                }
            }
            .navigationTitle("Add Budget Item")
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
        var item = BudgetItem(
            title: title,
            category: category,
            estimatedAmount: Double(estimatedAmount) ?? 0
        )
        item.eventId = eventId
        item.actualAmount = Double(actualAmount) ?? 0
        item.paidAmount = Double(paidAmount) ?? 0
        item.paidBy = paidBy
        item.notes = notes
        store.addBudgetItem(item)
        dismiss()
    }
}

// MARK: - Edit Budget Item
struct EditBudgetItemView: View {
    @EnvironmentObject var store: WeddingStore
    @Environment(\.dismiss) var dismiss
    @State private var item: BudgetItem

    init(item: BudgetItem) {
        _item = State(initialValue: item)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Item Details") {
                    TextField("Title", text: $item.title)
                    Picker("Category", selection: $item.category) {
                        ForEach(BudgetCategory.allCases, id: \.self) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }
                    Picker("Event", selection: $item.eventId) {
                        Text("General").tag(nil as UUID?)
                        ForEach(store.events) { event in
                            Text(event.name).tag(event.id as UUID?)
                        }
                    }
                }
                Section("Amounts (₹)") {
                    HStack {
                        Text("Estimated")
                        Spacer()
                        TextField("0", value: $item.estimatedAmount, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Actual")
                        Spacer()
                        TextField("0", value: $item.actualAmount, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Paid")
                        Spacer()
                        TextField("0", value: $item.paidAmount, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                Section("Responsibility") {
                    Picker("Paid By", selection: $item.paidBy) {
                        ForEach(FamilySide.allCases, id: \.self) { side in
                            Text(side.rawValue).tag(side)
                        }
                    }
                    Toggle("Approved", isOn: $item.isApproved)
                }
                Section("Notes") {
                    TextField("Notes...", text: $item.notes, axis: .vertical)
                        .lineLimit(2...4)
                }
                Section {
                    Button("Delete Item", role: .destructive) {
                        store.deleteBudgetItem(item)
                        dismiss()
                    }
                }
            }
            .navigationTitle("Edit Budget Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { store.updateBudgetItem(item); dismiss() }.fontWeight(.semibold)
                }
            }
        }
    }
}
