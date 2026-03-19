import SwiftUI

struct EventDetailView: View {
    @EnvironmentObject var store: WeddingStore
    @Environment(\.dismiss) var dismiss
    var event: WeddingEvent

    @State private var currentEvent: WeddingEvent
    @State private var showEdit = false
    @State private var showAddGuest = false
    @State private var showAssignVendor = false
    @State private var showAddBudget = false
    @State private var selectedTab = 0

    init(event: WeddingEvent) {
        self.event = event
        _currentEvent = State(initialValue: event)
    }

    var eventGuests: [Guest] {
        store.guestsForEvent(currentEvent.id)
    }

    var eventVendors: [Vendor] {
        store.vendorsForEvent(currentEvent.id)
    }

    var eventBudgetItems: [BudgetItem] {
        store.budgetItemsForEvent(currentEvent.id)
    }

    var daysUntil: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: currentEvent.date).day ?? 0
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Hero Header
                ZStack(alignment: .bottomLeading) {
                    Rectangle()
                        .fill(VivahTheme.gradient)
                        .frame(height: 200)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(currentEvent.name)
                            .font(.system(size: 32, weight: .bold, design: .serif))
                            .foregroundColor(VivahTheme.ivory)

                        HStack(spacing: 16) {
                            Label(currentEvent.date, style: .date, icon: "calendar")
                            Label(currentEvent.startTime, style: .time, icon: "clock")
                        }
                        .foregroundColor(VivahTheme.gold.opacity(0.9))
                        .font(.subheadline)
                    }
                    .padding(20)
                }

                // Quick info strip
                HStack(spacing: 0) {
                    QuickInfoCell(value: "\(daysUntil)", label: "Days Away", color: daysUntil < 7 ? .red : VivahTheme.deepRed)
                    Divider().frame(height: 40)
                    QuickInfoCell(value: "\(eventGuests.count)", label: "Guests", color: VivahTheme.gold)
                    Divider().frame(height: 40)
                    QuickInfoCell(value: "\(eventVendors.count)", label: "Vendors", color: VivahTheme.forestGreen)
                    Divider().frame(height: 40)
                    QuickInfoCell(value: store.totalSpendForEvent(currentEvent.id).inrShortFormatted, label: "Budget", color: VivahTheme.marigold)
                }
                .padding(.vertical, 14)
                .background(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)

                // Tab Picker
                Picker("", selection: $selectedTab) {
                    Text("Overview").tag(0)
                    Text("Guests").tag(1)
                    Text("Vendors").tag(2)
                    Text("Budget").tag(3)
                }
                .pickerStyle(.segmented)
                .padding(16)
                .background(Color(.systemBackground))

                // Tab Content
                VStack(spacing: 16) {
                    switch selectedTab {
                    case 0: EventOverviewTab(event: currentEvent)
                    case 1: EventGuestsTab(event: currentEvent, guests: eventGuests, showAddGuest: $showAddGuest)
                        .environmentObject(store)
                    case 2: EventVendorsTab(event: currentEvent, vendors: eventVendors, showAssignVendor: $showAssignVendor)
                        .environmentObject(store)
                    case 3: EventBudgetTab(event: currentEvent, budgetItems: eventBudgetItems, showAddBudget: $showAddBudget)
                        .environmentObject(store)
                    default: EmptyView()
                    }
                }
                .padding(16)
                .padding(.bottom, 20)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showEdit = true }) {
                    Image(systemName: "pencil.circle.fill")
                        .foregroundColor(VivahTheme.gold)
                }
            }
        }
        .sheet(isPresented: $showEdit) {
            EditEventView(event: currentEvent) { updated in
                store.updateEvent(updated)
                currentEvent = updated
            }
        }
        .onReceive(store.$events) { events in
            if let updated = events.first(where: { $0.id == event.id }) {
                currentEvent = updated
            }
        }
    }
}

// MARK: - Quick Info Cell
struct QuickInfoCell: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Label with Date/Time helper
extension Label where Title == Text, Icon == Image {
    init(_ date: Date, style: Text.DateStyle, icon: String) {
        self.init {
            Text(date, style: style)
        } icon: {
            Image(systemName: icon)
        }
    }
}

// MARK: - Overview Tab
struct EventOverviewTab: View {
    let event: WeddingEvent

    var body: some View {
        VStack(spacing: 14) {
            if !event.venue.isEmpty {
                InfoCard(title: "Venue") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(event.venue)
                            .font(.subheadline).fontWeight(.semibold)
                        if !event.venueAddress.isEmpty {
                            Text(event.venueAddress)
                                .font(.caption).foregroundColor(.secondary)
                        }
                    }
                }
            }

            InfoCard(title: "Schedule") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("Date", systemImage: "calendar")
                            .font(.caption).foregroundColor(.secondary)
                        Spacer()
                        Text(event.date, style: .date)
                            .font(.subheadline).fontWeight(.medium)
                    }
                    HStack {
                        Label("Time", systemImage: "clock")
                            .font(.caption).foregroundColor(.secondary)
                        Spacer()
                        Text("\(event.startTime, style: .time) – \(event.endTime, style: .time)")
                            .font(.subheadline).fontWeight(.medium)
                    }
                    if event.guestCapacity > 0 {
                        HStack {
                            Label("Capacity", systemImage: "person.2")
                                .font(.caption).foregroundColor(.secondary)
                            Spacer()
                            Text("\(event.guestCapacity) guests")
                                .font(.subheadline).fontWeight(.medium)
                        }
                    }
                    if !event.dressCode.isEmpty {
                        HStack {
                            Label("Dress Code", systemImage: "tshirt")
                                .font(.caption).foregroundColor(.secondary)
                            Spacer()
                            Text(event.dressCode)
                                .font(.subheadline).fontWeight(.medium)
                        }
                    }
                }
            }

            if !event.notes.isEmpty {
                InfoCard(title: "Notes") {
                    Text(event.notes)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct InfoCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.caption).fontWeight(.semibold)
                .foregroundColor(VivahTheme.deepRed)
                .kerning(0.5)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 1)
    }
}

// MARK: - Guests Tab
struct EventGuestsTab: View {
    @EnvironmentObject var store: WeddingStore
    let event: WeddingEvent
    let guests: [Guest]
    @Binding var showAddGuest: Bool

    var confirmedCount: Int { guests.filter { $0.rsvpStatus == .confirmed }.count }
    var pendingCount: Int { guests.filter { $0.rsvpStatus == .pending }.count }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(guests.count) Guests")
                        .font(.headline)
                    Text("\(confirmedCount) confirmed • \(pendingCount) pending")
                        .font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                Button(action: { showAddGuest = true }) {
                    Label("Add", systemImage: "plus")
                        .font(.subheadline).fontWeight(.semibold)
                        .padding(.horizontal, 14).padding(.vertical, 7)
                        .background(VivahTheme.deepRed)
                        .foregroundColor(.white)
                        .cornerRadius(20)
                }
            }

            if guests.isEmpty {
                Text("No guests assigned to this event yet.")
                    .font(.subheadline).foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(guests) { guest in
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(VivahTheme.gold.opacity(0.2))
                                .frame(width: 38, height: 38)
                            Text(guest.initials)
                                .font(.caption).fontWeight(.bold)
                                .foregroundColor(VivahTheme.deepRed)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(guest.fullName)
                                .font(.subheadline).fontWeight(.medium)
                            Text(guest.relationship.isEmpty ? guest.relationshipSide.rawValue : guest.relationship)
                                .font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        Text(guest.rsvpStatus.rawValue)
                            .font(.caption).fontWeight(.medium)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(guest.rsvpStatus.color.opacity(0.15))
                            .foregroundColor(guest.rsvpStatus.color)
                            .cornerRadius(8)
                    }
                    .padding(10)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                }
            }
        }
    }
}

// MARK: - Vendors Tab
struct EventVendorsTab: View {
    @EnvironmentObject var store: WeddingStore
    let event: WeddingEvent
    let vendors: [Vendor]
    @Binding var showAssignVendor: Bool

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("\(vendors.count) Vendors")
                    .font(.headline)
                Spacer()
                Button(action: { showAssignVendor = true }) {
                    Label("Assign", systemImage: "plus")
                        .font(.subheadline).fontWeight(.semibold)
                        .padding(.horizontal, 14).padding(.vertical, 7)
                        .background(VivahTheme.deepRed)
                        .foregroundColor(.white)
                        .cornerRadius(20)
                }
            }

            if vendors.isEmpty {
                Text("No vendors assigned to this event yet.")
                    .font(.subheadline).foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(vendors) { vendor in
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(VivahTheme.gold.opacity(0.15))
                                .frame(width: 40, height: 40)
                            Image(systemName: vendor.category.icon)
                                .foregroundColor(VivahTheme.gold)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(vendor.name)
                                .font(.subheadline).fontWeight(.medium)
                            Text(vendor.category.rawValue)
                                .font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(vendor.contractAmount.inrShortFormatted)
                                .font(.caption).fontWeight(.semibold)
                            Text("Balance: \(vendor.balanceDue.inrShortFormatted)")
                                .font(.caption2).foregroundColor(.orange)
                        }
                    }
                    .padding(10)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                }
            }
        }
    }
}

// MARK: - Budget Tab
struct EventBudgetTab: View {
    @EnvironmentObject var store: WeddingStore
    let event: WeddingEvent
    let budgetItems: [BudgetItem]
    @Binding var showAddBudget: Bool

    var totalEstimated: Double { budgetItems.reduce(0) { $0 + $1.estimatedAmount } }
    var totalActual: Double { budgetItems.reduce(0) { $0 + $1.actualAmount } }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Event Budget")
                        .font(.headline)
                    HStack {
                        Text("Est: \(totalEstimated.inrShortFormatted)")
                            .font(.caption).foregroundColor(.secondary)
                        Text("•")
                        Text("Actual: \(totalActual.inrShortFormatted)")
                            .font(.caption).foregroundColor(VivahTheme.deepRed)
                    }
                }
                Spacer()
                Button(action: { showAddBudget = true }) {
                    Label("Add", systemImage: "plus")
                        .font(.subheadline).fontWeight(.semibold)
                        .padding(.horizontal, 14).padding(.vertical, 7)
                        .background(VivahTheme.deepRed)
                        .foregroundColor(.white)
                        .cornerRadius(20)
                }
            }

            if budgetItems.isEmpty {
                Text("No budget items for this event.")
                    .font(.subheadline).foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(budgetItems) { item in
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(item.title)
                                .font(.subheadline).fontWeight(.medium)
                            HStack(spacing: 4) {
                                Text(item.category.rawValue)
                                    .font(.caption2).foregroundColor(.secondary)
                                Text("•")
                                Text(item.paidBy.rawValue)
                                    .font(.caption2).foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(item.actualAmount.inrShortFormatted)
                                .font(.subheadline).fontWeight(.semibold)
                            Text("Est: \(item.estimatedAmount.inrShortFormatted)")
                                .font(.caption2).foregroundColor(.secondary)
                        }
                    }
                    .padding(10)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                }
            }
        }
    }
}

// MARK: - Edit Event View
struct EditEventView: View {
    @Environment(\.dismiss) var dismiss
    @State private var event: WeddingEvent
    let onSave: (WeddingEvent) -> Void

    init(event: WeddingEvent, onSave: @escaping (WeddingEvent) -> Void) {
        _event = State(initialValue: event)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Event Details") {
                    TextField("Event Name", text: $event.name)
                    DatePicker("Date", selection: $event.date, displayedComponents: .date)
                    DatePicker("Start Time", selection: $event.startTime, displayedComponents: .hourAndMinute)
                    DatePicker("End Time", selection: $event.endTime, displayedComponents: .hourAndMinute)
                }
                Section("Venue") {
                    TextField("Venue Name", text: $event.venue)
                    TextField("Address", text: $event.venueAddress)
                    Stepper("Capacity: \(event.guestCapacity)", value: $event.guestCapacity, in: 10...5000, step: 10)
                }
                Section("Other") {
                    TextField("Dress Code", text: $event.dressCode)
                    TextField("Notes", text: $event.notes, axis: .vertical)
                        .lineLimit(3...6)
                    Toggle("Completed", isOn: $event.isCompleted)
                }
            }
            .navigationTitle("Edit Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { onSave(event); dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }
}
