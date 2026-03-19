import SwiftUI

struct ShagunTrackerView: View {
    @EnvironmentObject var store: WeddingStore
    @State private var showAddEntry = false
    @State private var searchText = ""
    @State private var selectedFilter: ShagunFilter = .all
    @State private var selectedSide: RelationshipSide? = nil
    @State private var sortMode: SortMode = .date

    enum ShagunFilter: String, CaseIterable {
        case all = "All"
        case cash = "Cash"
        case gifts = "Gifts"
        case thankYouPending = "Thank You Pending"
    }

    enum SortMode: String, CaseIterable {
        case date = "Date"
        case amount = "Amount"
        case name = "Name"
    }

    var filteredEntries: [ShagunEntry] {
        var entries = store.shagunEntries

        if !searchText.isEmpty {
            entries = entries.filter {
                $0.fromName.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText)
            }
        }

        switch selectedFilter {
        case .all: break
        case .cash: entries = entries.filter { $0.shagunType == .cash || $0.shagunType == .cheque || $0.shagunType == .online }
        case .gifts: entries = entries.filter { $0.shagunType == .gift || $0.shagunType == .jewelery || $0.shagunType == .clothes }
        case .thankYouPending: entries = entries.filter { !$0.thankYouSent }
        }

        if let side = selectedSide {
            entries = entries.filter { $0.relationshipSide == side }
        }

        switch sortMode {
        case .date: return entries.sorted { $0.receivedDate > $1.receivedDate }
        case .amount: return entries.sorted { $0.amount > $1.amount }
        case .name: return entries.sorted { $0.fromName < $1.fromName }
        }
    }

    var cashTotal: Double {
        store.shagunEntries.filter {
            $0.shagunType == .cash || $0.shagunType == .cheque || $0.shagunType == .online
        }.reduce(0) { $0 + $1.amount }
    }

    var thankYouPendingCount: Int {
        store.shagunEntries.filter { !$0.thankYouSent }.count
    }

    var body: some View {
        VStack(spacing: 0) {
            // Stats Header
            ShagunStatsHeader(
                totalAmount: store.totalShagunAmount,
                cashAmount: cashTotal,
                totalEntries: store.shagunEntries.count,
                thankYouPending: thankYouPendingCount
            )

            // Search + Filters
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                    TextField("Search by name...", text: $searchText)
                    Menu {
                        ForEach(SortMode.allCases, id: \.self) { mode in
                            Button(mode.rawValue) { sortMode = mode }
                        }
                    } label: {
                        Label("Sort: \(sortMode.rawValue)", systemImage: "arrow.up.arrow.down")
                            .font(.caption)
                            .foregroundColor(VivahTheme.deepRed)
                    }
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(10)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(ShagunFilter.allCases, id: \.self) { filter in
                            FilterChip(title: filter.rawValue, isSelected: selectedFilter == filter) {
                                selectedFilter = filter
                            }
                        }
                        Divider().frame(height: 24)
                        ForEach(RelationshipSide.allCases, id: \.self) { side in
                            FilterChip(
                                title: side.rawValue.components(separatedBy: "'").first ?? "",
                                isSelected: selectedSide == side
                            ) {
                                selectedSide = selectedSide == side ? nil : side
                            }
                        }
                    }
                }
            }
            .padding(12)
            .background(Color(.systemBackground))

            // List
            if filteredEntries.isEmpty {
                EmptyStateView(icon: "gift", title: "No Shagun Entries", subtitle: "Tap + to record a gift or shagun")
            } else {
                List {
                    ForEach(filteredEntries) { entry in
                        ShagunEntryRow(entry: entry)
                            .environmentObject(store)
                    }
                    .onDelete { offsets in
                        offsets.forEach { i in store.deleteShagunEntry(filteredEntries[i]) }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Shagun & Gifts")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAddEntry = true }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(VivahTheme.deepRed)
                        .font(.title3)
                }
            }
        }
        .sheet(isPresented: $showAddEntry) {
            AddShagunView()
                .environmentObject(store)
        }
    }
}

// MARK: - Stats Header
struct ShagunStatsHeader: View {
    let totalAmount: Double
    let cashAmount: Double
    let totalEntries: Int
    let thankYouPending: Int

    var body: some View {
        ZStack {
            Rectangle()
                .fill(VivahTheme.gradient)

            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total Received")
                            .font(.caption).foregroundColor(VivahTheme.ivory.opacity(0.7))
                        Text(totalAmount.inrFormatted)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(VivahTheme.gold)
                    }
                    Spacer()
                    Image(systemName: "gift.fill")
                        .font(.system(size: 36))
                        .foregroundColor(VivahTheme.gold.opacity(0.3))
                }

                HStack(spacing: 0) {
                    ShagunMiniStat(value: cashAmount.inrShortFormatted, label: "Cash/Transfer")
                    Divider().frame(height: 30).background(VivahTheme.ivory.opacity(0.3))
                    ShagunMiniStat(value: "\(totalEntries)", label: "Total Gifts")
                    Divider().frame(height: 30).background(VivahTheme.ivory.opacity(0.3))
                    ShagunMiniStat(value: "\(thankYouPending)", label: "Thank You Due", color: thankYouPending > 0 ? Color.orange : VivahTheme.ivory)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .frame(height: 130)
    }
}

struct ShagunMiniStat: View {
    let value: String
    let label: String
    var color: Color = VivahTheme.ivory

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(VivahTheme.ivory.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Shagun Entry Row
struct ShagunEntryRow: View {
    @EnvironmentObject var store: WeddingStore
    let entry: ShagunEntry
    @State private var showDetail = false

    var eventName: String {
        if let eid = entry.eventId, let event = store.events.first(where: { $0.id == eid }) {
            return event.name
        }
        return "General"
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(typeColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: typeIcon)
                    .foregroundColor(typeColor)
                    .font(.system(size: 16))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(entry.fromName)
                    .font(.subheadline).fontWeight(.semibold)
                HStack(spacing: 4) {
                    Text(eventName)
                        .font(.caption2).foregroundColor(.secondary)
                    Text("•")
                    Text(entry.receivedDate, style: .date)
                        .font(.caption2).foregroundColor(.secondary)
                }
                if !entry.description.isEmpty {
                    Text(entry.description)
                        .font(.caption2).foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if entry.amount > 0 {
                    Text(entry.amount.inrShortFormatted)
                        .font(.subheadline).fontWeight(.bold)
                        .foregroundColor(VivahTheme.deepRed)
                }
                HStack(spacing: 4) {
                    Text(entry.shagunType.rawValue)
                        .font(.caption2)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(typeColor.opacity(0.1))
                        .foregroundColor(typeColor)
                        .cornerRadius(4)
                }
                if entry.thankYouSent {
                    Label("Thanks Sent", systemImage: "checkmark.circle")
                        .font(.caption2)
                        .foregroundColor(.green)
                } else {
                    Text("Thank You Due")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture { showDetail = true }
        .sheet(isPresented: $showDetail) {
            ShagunDetailView(entry: entry)
                .environmentObject(store)
        }
    }

    var typeIcon: String {
        switch entry.shagunType {
        case .cash: return "banknote.fill"
        case .cheque: return "doc.text.fill"
        case .gift: return "gift.fill"
        case .jewelery: return "star.fill"
        case .clothes: return "tag.fill"
        case .online: return "arrow.up.right.square.fill"
        }
    }

    var typeColor: Color {
        switch entry.shagunType {
        case .cash, .cheque, .online: return VivahTheme.forestGreen
        case .gift: return VivahTheme.marigold
        case .jewelery: return VivahTheme.gold
        case .clothes: return VivahTheme.deepRed
        }
    }
}

// MARK: - Shagun Detail View
struct ShagunDetailView: View {
    @EnvironmentObject var store: WeddingStore
    @Environment(\.dismiss) var dismiss
    @State var entry: ShagunEntry

    init(entry: ShagunEntry) {
        _entry = State(initialValue: entry)
    }

    var eventName: String {
        if let eid = entry.eventId, let event = store.events.first(where: { $0.id == eid }) {
            return event.name
        }
        return "General"
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Gift Details") {
                    DetailRow(label: "From", value: entry.fromName)
                    DetailRow(label: "Type", value: entry.shagunType.rawValue)
                    if entry.amount > 0 {
                        DetailRow(label: "Amount", value: entry.amount.inrFormatted)
                    }
                    DetailRow(label: "Event", value: eventName)
                    DetailRow(label: "Date", value: entry.receivedDate.formatted(date: .medium, time: .omitted))
                    DetailRow(label: "Relationship Side", value: entry.relationshipSide.rawValue)
                    if !entry.description.isEmpty {
                        DetailRow(label: "Description", value: entry.description)
                    }
                }

                Section("Thank You Status") {
                    Toggle("Thank You Sent", isOn: $entry.thankYouSent)
                        .onChange(of: entry.thankYouSent) { sent in
                            if sent { entry.thankYouDate = Date() }
                            else { entry.thankYouDate = nil }
                            store.updateShagunEntry(entry)
                        }
                    if let td = entry.thankYouDate {
                        DetailRow(label: "Thank You Sent On", value: td.formatted(date: .medium, time: .omitted))
                    }
                }

                if !entry.notes.isEmpty {
                    Section("Notes") {
                        Text(entry.notes).font(.subheadline)
                    }
                }

                Section {
                    Button("Delete Entry", role: .destructive) {
                        store.deleteShagunEntry(entry)
                        dismiss()
                    }
                }
            }
            .navigationTitle(entry.fromName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Add Shagun View
struct AddShagunView: View {
    @EnvironmentObject var store: WeddingStore
    @Environment(\.dismiss) var dismiss

    @State private var fromName = ""
    @State private var amount = ""
    @State private var shagunType: ShagunType = .cash
    @State private var eventId: UUID? = nil
    @State private var description = ""
    @State private var receivedDate = Date()
    @State private var thankYouSent = false
    @State private var relationshipSide: RelationshipSide = .brideSide
    @State private var notes = ""
    @State private var selectedGuestId: UUID? = nil
    @State private var selectedHouseholdId: UUID? = nil

    var body: some View {
        NavigationStack {
            Form {
                Section("Gift From") {
                    TextField("Name (Person or Family)", text: $fromName)

                    if !store.guests.isEmpty {
                        Picker("Link to Guest (Optional)", selection: $selectedGuestId) {
                            Text("None").tag(nil as UUID?)
                            ForEach(store.guests) { guest in
                                Text(guest.fullName).tag(guest.id as UUID?)
                            }
                        }
                        .onChange(of: selectedGuestId) { gid in
                            if let gid = gid, let guest = store.guests.first(where: { $0.id == gid }) {
                                fromName = guest.fullName
                                relationshipSide = guest.relationshipSide
                            }
                        }
                    }

                    Picker("Side", selection: $relationshipSide) {
                        ForEach(RelationshipSide.allCases, id: \.self) { side in
                            Text(side.rawValue).tag(side)
                        }
                    }
                }

                Section("Gift Details") {
                    Picker("Type", selection: $shagunType) {
                        ForEach(ShagunType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)

                    HStack {
                        Text("Amount (₹)")
                        Spacer()
                        TextField("0", text: $amount)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }

                    TextField("Description (e.g. Gold necklace, ₹5100 shagun)", text: $description)
                    DatePicker("Received On", selection: $receivedDate, displayedComponents: .date)

                    Picker("Event", selection: $eventId) {
                        Text("General").tag(nil as UUID?)
                        ForEach(store.events) { event in
                            Text(event.name).tag(event.id as UUID?)
                        }
                    }
                }

                Section("Thank You") {
                    Toggle("Thank You Already Sent", isOn: $thankYouSent)
                }

                Section("Notes") {
                    TextField("Any notes...", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("Record Shagun / Gift")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { saveEntry() }
                        .disabled(fromName.isEmpty)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    func saveEntry() {
        var entry = ShagunEntry(
            fromName: fromName,
            amount: Double(amount) ?? 0,
            shagunType: shagunType
        )
        entry.fromGuestId = selectedGuestId
        entry.fromHouseholdId = selectedHouseholdId
        entry.eventId = eventId
        entry.description = description
        entry.receivedDate = receivedDate
        entry.thankYouSent = thankYouSent
        if thankYouSent { entry.thankYouDate = Date() }
        entry.relationshipSide = relationshipSide
        entry.notes = notes
        store.addShagunEntry(entry)
        dismiss()
    }
}
