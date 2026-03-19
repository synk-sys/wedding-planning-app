import SwiftUI

struct GuestManagementView: View {
    @EnvironmentObject var store: WeddingStore
    @State private var showAddGuest = false
    @State private var showAddHousehold = false
    @State private var searchText = ""
    @State private var selectedView: GuestViewMode = .list
    @State private var selectedFilter: GuestFilter = .all
    @State private var selectedSide: RelationshipSide? = nil

    enum GuestViewMode: String, CaseIterable {
        case list = "Guests"
        case households = "Households"
        case byEvent = "By Event"
    }

    enum GuestFilter: String, CaseIterable {
        case all = "All"
        case confirmed = "Confirmed"
        case pending = "Pending"
        case declined = "Declined"
    }

    var filteredGuests: [Guest] {
        var guests = store.guests

        if !searchText.isEmpty {
            guests = guests.filter {
                $0.fullName.localizedCaseInsensitiveContains(searchText) ||
                $0.phone.contains(searchText) ||
                $0.relationship.localizedCaseInsensitiveContains(searchText)
            }
        }

        switch selectedFilter {
        case .all: break
        case .confirmed: guests = guests.filter { $0.rsvpStatus == .confirmed }
        case .pending: guests = guests.filter { $0.rsvpStatus == .pending }
        case .declined: guests = guests.filter { $0.rsvpStatus == .declined }
        }

        if let side = selectedSide {
            guests = guests.filter { $0.relationshipSide == side }
        }

        return guests.sorted { $0.fullName < $1.fullName }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Stats bar
                GuestStatsBar()
                    .environmentObject(store)

                // View mode picker
                Picker("View", selection: $selectedView) {
                    ForEach(GuestViewMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(.systemBackground))

                // Search bar (guest list only)
                if selectedView == .list {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search guests...", text: $searchText)
                    }
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                    .background(Color(.systemBackground))

                    // Filter pills
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterChip(title: "All", isSelected: selectedFilter == .all) {
                                selectedFilter = .all
                            }
                            ForEach(GuestFilter.allCases.dropFirst(), id: \.self) { filter in
                                FilterChip(title: filter.rawValue, isSelected: selectedFilter == filter) {
                                    selectedFilter = filter
                                }
                            }
                            Divider().frame(height: 24)
                            ForEach(RelationshipSide.allCases, id: \.self) { side in
                                FilterChip(title: side.rawValue.components(separatedBy: "'").first ?? side.rawValue,
                                          isSelected: selectedSide == side) {
                                    selectedSide = selectedSide == side ? nil : side
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 10)
                    }
                    .background(Color(.systemBackground))
                }

                // Content
                switch selectedView {
                case .list:
                    GuestListView(guests: filteredGuests)
                        .environmentObject(store)
                case .households:
                    HouseholdsListView()
                        .environmentObject(store)
                case .byEvent:
                    GuestsByEventView()
                        .environmentObject(store)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Guests")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showAddGuest = true }) {
                            Label("Add Guest", systemImage: "person.badge.plus")
                        }
                        Button(action: { showAddHousehold = true }) {
                            Label("Add Household", systemImage: "house.badge.plus")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(VivahTheme.deepRed)
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showAddGuest) {
                AddGuestView()
                    .environmentObject(store)
            }
            .sheet(isPresented: $showAddHousehold) {
                AddHouseholdView()
                    .environmentObject(store)
            }
        }
    }
}

// MARK: - Stats Bar
struct GuestStatsBar: View {
    @EnvironmentObject var store: WeddingStore

    var body: some View {
        HStack(spacing: 0) {
            GuestStatItem(count: store.guests.count, label: "Total", color: .primary)
            Divider().frame(height: 36)
            GuestStatItem(count: store.confirmedGuestCount, label: "Confirmed", color: .green)
            Divider().frame(height: 36)
            GuestStatItem(count: store.pendingRSVPCount, label: "Pending", color: .orange)
            Divider().frame(height: 36)
            GuestStatItem(count: store.guests.filter { $0.rsvpStatus == .declined }.count, label: "Declined", color: .red)
            Divider().frame(height: 36)
            GuestStatItem(count: store.households.count, label: "Households", color: VivahTheme.gold)
        }
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct GuestStatItem: View {
    let count: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Guest List View
struct GuestListView: View {
    @EnvironmentObject var store: WeddingStore
    let guests: [Guest]

    var groupedGuests: [String: [Guest]] {
        Dictionary(grouping: guests) { String($0.firstName.prefix(1)).uppercased() }
    }

    var sortedKeys: [String] {
        groupedGuests.keys.sorted()
    }

    var body: some View {
        if guests.isEmpty {
            EmptyStateView(icon: "person.3", title: "No Guests Found", subtitle: "Tap + to add guests")
        } else {
            List {
                ForEach(sortedKeys, id: \.self) { key in
                    Section(key) {
                        ForEach(groupedGuests[key] ?? []) { guest in
                            NavigationLink {
                                GuestDetailView(guest: guest)
                                    .environmentObject(store)
                            } label: {
                                GuestRow(guest: guest)
                                    .environmentObject(store)
                            }
                        }
                        .onDelete { offsets in
                            if let guestArr = groupedGuests[key] {
                                offsets.forEach { i in
                                    store.deleteGuest(guestArr[i])
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
    }
}

struct GuestRow: View {
    @EnvironmentObject var store: WeddingStore
    let guest: Guest

    var householdName: String {
        if let hid = guest.householdId, let h = store.households.first(where: { $0.id == hid }) {
            return h.familyName
        }
        return ""
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(sideColor.opacity(0.2))
                    .frame(width: 42, height: 42)
                Text(guest.initials)
                    .font(.subheadline).fontWeight(.bold)
                    .foregroundColor(sideColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(guest.fullName)
                        .font(.subheadline).fontWeight(.semibold)
                    if guest.isVIP {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(VivahTheme.gold)
                    }
                }
                HStack(spacing: 4) {
                    Text(guest.relationship.isEmpty ? guest.relationshipSide.rawValue : guest.relationship)
                        .font(.caption).foregroundColor(.secondary)
                    if !householdName.isEmpty {
                        Text("•")
                        Text(householdName)
                            .font(.caption).foregroundColor(.secondary)
                    }
                }
                HStack(spacing: 6) {
                    Text("\(guest.eventsAttending.count) events")
                        .font(.caption2).foregroundColor(.secondary)
                    if guest.dietaryPreference != .noRestriction {
                        Text(guest.dietaryPreference.rawValue)
                            .font(.caption2)
                            .padding(.horizontal, 5).padding(.vertical, 1)
                            .background(Color.green.opacity(0.1))
                            .foregroundColor(.green)
                            .cornerRadius(4)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(guest.rsvpStatus.rawValue)
                    .font(.caption).fontWeight(.medium)
                    .padding(.horizontal, 7).padding(.vertical, 2)
                    .background(guest.rsvpStatus.color.opacity(0.15))
                    .foregroundColor(guest.rsvpStatus.color)
                    .cornerRadius(6)
                if !guest.phone.isEmpty {
                    Image(systemName: "phone.fill")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    var sideColor: Color {
        switch guest.relationshipSide {
        case .brideSide: return VivahTheme.deepRed
        case .groomSide: return VivahTheme.gold
        case .mutual: return VivahTheme.forestGreen
        case .other: return .secondary
        }
    }
}

// MARK: - Guest Detail View
struct GuestDetailView: View {
    @EnvironmentObject var store: WeddingStore
    @Environment(\.dismiss) var dismiss
    @State var guest: Guest
    @State private var showEdit = false

    var attendingEvents: [WeddingEvent] {
        store.events.filter { guest.eventsAttending.contains($0.id) }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                VStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(VivahTheme.gradient)
                            .frame(width: 80, height: 80)
                        Text(guest.initials)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(VivahTheme.ivory)
                    }
                    Text(guest.fullName)
                        .font(.title2).fontWeight(.bold)
                    HStack(spacing: 8) {
                        Text(guest.rsvpStatus.rawValue)
                            .font(.caption).fontWeight(.semibold)
                            .padding(.horizontal, 10).padding(.vertical, 4)
                            .background(guest.rsvpStatus.color.opacity(0.2))
                            .foregroundColor(guest.rsvpStatus.color)
                            .cornerRadius(10)
                        if guest.isVIP {
                            Label("VIP", systemImage: "star.fill")
                                .font(.caption)
                                .foregroundColor(VivahTheme.gold)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(20)
                .background(Color(.systemBackground))
                .cornerRadius(16)

                // Contact info
                InfoCard(title: "Contact") {
                    VStack(spacing: 8) {
                        if !guest.phone.isEmpty {
                            HStack {
                                Label(guest.phone, systemImage: "phone")
                                    .font(.subheadline)
                                Spacer()
                                if guest.whatsappOptIn {
                                    Label("WhatsApp", systemImage: "message.fill")
                                        .font(.caption).foregroundColor(.green)
                                }
                            }
                        }
                        if !guest.email.isEmpty {
                            Label(guest.email, systemImage: "envelope")
                                .font(.subheadline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        if !guest.city.isEmpty {
                            Label(guest.city, systemImage: "location")
                                .font(.subheadline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }

                // Details
                InfoCard(title: "Details") {
                    VStack(spacing: 8) {
                        DetailRow(label: "Relationship Side", value: guest.relationshipSide.rawValue)
                        if !guest.relationship.isEmpty {
                            DetailRow(label: "Relationship", value: guest.relationship)
                        }
                        DetailRow(label: "Dietary", value: guest.dietaryPreference.rawValue)
                        if guest.plusOne {
                            DetailRow(label: "Plus One", value: guest.plusOneName.isEmpty ? "Yes" : guest.plusOneName)
                        }
                        if !guest.tableNumber.isEmpty {
                            DetailRow(label: "Table", value: guest.tableNumber)
                        }
                    }
                }

                // Events attending
                InfoCard(title: "Events Attending (\(attendingEvents.count))") {
                    if attendingEvents.isEmpty {
                        Text("Not assigned to any event")
                            .font(.subheadline).foregroundColor(.secondary)
                    } else {
                        VStack(spacing: 6) {
                            ForEach(attendingEvents) { event in
                                HStack {
                                    Image(systemName: "calendar")
                                        .font(.caption).foregroundColor(VivahTheme.gold)
                                    Text(event.name)
                                        .font(.subheadline)
                                    Spacer()
                                    Text(event.date, style: .date)
                                        .font(.caption).foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }

                if !guest.phone.isEmpty && guest.whatsappOptIn {
                    Button(action: sendWhatsApp) {
                        Label("Send WhatsApp RSVP", systemImage: "message.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(red: 0.07, green: 0.62, blue: 0.42))
                            .foregroundColor(.white)
                            .cornerRadius(14)
                            .fontWeight(.semibold)
                    }
                }

                if !guest.notes.isEmpty {
                    InfoCard(title: "Notes") {
                        Text(guest.notes).font(.subheadline).foregroundColor(.secondary)
                    }
                }
            }
            .padding(16)
            .padding(.bottom, 20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(guest.firstName)
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
            AddGuestView(editGuest: guest)
                .environmentObject(store)
        }
        .onReceive(store.$guests) { guests in
            if let updated = guests.first(where: { $0.id == guest.id }) {
                guest = updated
            }
        }
    }

    func sendWhatsApp() {
        let eventNames = attendingEvents.map { $0.name }
        let urlStr = store.generateWhatsAppRSVPLink(for: guest, eventNames: eventNames)
        if let url = URL(string: urlStr) {
            UIApplication.shared.open(url)
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.caption).foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline).fontWeight(.medium)
        }
    }
}

// MARK: - Households List
struct HouseholdsListView: View {
    @EnvironmentObject var store: WeddingStore

    var body: some View {
        if store.households.isEmpty {
            EmptyStateView(icon: "house", title: "No Households", subtitle: "Group guests into families using households")
        } else {
            List {
                ForEach(store.households) { household in
                    NavigationLink {
                        HouseholdDetailView(household: household)
                            .environmentObject(store)
                    } label: {
                        HouseholdRow(household: household)
                            .environmentObject(store)
                    }
                }
                .onDelete { offsets in
                    offsets.forEach { i in
                        store.deleteHousehold(store.households[i])
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
    }
}

struct HouseholdRow: View {
    @EnvironmentObject var store: WeddingStore
    let household: Household

    var members: [Guest] {
        store.guestsInHousehold(household.id)
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(VivahTheme.gold.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: "house.fill")
                    .foregroundColor(VivahTheme.gold)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(household.familyName)
                    .font(.subheadline).fontWeight(.semibold)
                Text("\(members.count) members • \(household.relationshipSide.rawValue)")
                    .font(.caption).foregroundColor(.secondary)
                if !household.city.isEmpty {
                    Label(household.city, systemImage: "location")
                        .font(.caption2).foregroundColor(.secondary)
                }
            }
            Spacer()
            if household.giftGiven {
                Image(systemName: "gift.fill")
                    .font(.caption)
                    .foregroundColor(VivahTheme.gold)
            }
        }
        .padding(.vertical, 4)
    }
}

struct HouseholdDetailView: View {
    @EnvironmentObject var store: WeddingStore
    @State var household: Household

    var members: [Guest] {
        store.guestsInHousehold(household.id)
    }

    var body: some View {
        List {
            Section("Family Info") {
                if !household.headOfFamily.isEmpty {
                    DetailRow(label: "Head of Family", value: household.headOfFamily)
                }
                DetailRow(label: "Side", value: household.relationshipSide.rawValue)
                if !household.relationship.isEmpty {
                    DetailRow(label: "Relationship", value: household.relationship)
                }
                if !household.phone.isEmpty {
                    DetailRow(label: "Phone", value: household.phone)
                }
                if !household.address.isEmpty {
                    DetailRow(label: "Address", value: household.address)
                }
                if !household.city.isEmpty {
                    DetailRow(label: "City", value: household.city)
                }
            }
            Section("Members (\(members.count))") {
                ForEach(members) { member in
                    HStack {
                        Text(member.fullName)
                        Spacer()
                        Text(member.rsvpStatus.rawValue)
                            .font(.caption)
                            .foregroundColor(member.rsvpStatus.color)
                    }
                }
            }
        }
        .navigationTitle(household.familyName)
    }
}

// MARK: - Guests By Event
struct GuestsByEventView: View {
    @EnvironmentObject var store: WeddingStore

    var body: some View {
        if store.events.isEmpty {
            EmptyStateView(icon: "calendar", title: "No Events", subtitle: "Add events first")
        } else {
            List {
                ForEach(store.events) { event in
                    let guests = store.guestsForEvent(event.id)
                    Section {
                        HStack {
                            Text(event.name).fontWeight(.semibold)
                            Spacer()
                            Text("\(guests.count) guests")
                                .font(.caption).foregroundColor(.secondary)
                        }
                        ForEach(guests) { guest in
                            HStack {
                                Text(guest.fullName).font(.subheadline)
                                Spacer()
                                Text(guest.rsvpStatus.rawValue)
                                    .font(.caption)
                                    .foregroundColor(guest.rsvpStatus.color)
                            }
                        }
                        if guests.isEmpty {
                            Text("No guests assigned")
                                .font(.caption).foregroundColor(.secondary)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
    }
}
