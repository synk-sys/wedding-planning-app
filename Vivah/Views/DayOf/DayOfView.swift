import SwiftUI

struct DayOfView: View {
    @EnvironmentObject var store: WeddingStore
    @State private var selectedEvent: WeddingEvent?
    @State private var currentTime = Date()
    @State private var showVendorContacts = false
    let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var todayEvents: [WeddingEvent] {
        let cal = Calendar.current
        return store.events.filter { cal.isDateInToday($0.date) }.sorted { $0.startTime < $1.startTime }
    }

    var upcomingEvents: [WeddingEvent] {
        store.upcomingEvents.prefix(5).map { $0 }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Live time header
                DayOfHeroCard(currentTime: currentTime, wedding: store.wedding)

                // Select event for day-of dashboard
                if !store.events.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Select Event", systemImage: "calendar.badge.clock")
                            .font(.subheadline).fontWeight(.semibold)
                            .foregroundColor(VivahTheme.deepRed)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(upcomingEvents) { event in
                                    EventSelectPill(
                                        event: event,
                                        isSelected: selectedEvent?.id == event.id,
                                        action: { selectedEvent = event }
                                    )
                                }
                            }
                        }
                    }
                    .padding(16)
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
                }

                // Today's events
                if !todayEvents.isEmpty {
                    TodayTimelineCard(events: todayEvents, currentTime: currentTime)
                        .environmentObject(store)
                }

                // Selected event dashboard
                if let event = selectedEvent {
                    EventDayOfDashboard(event: event)
                        .environmentObject(store)
                }

                // Emergency contacts
                EmergencyContactsCard()
                    .environmentObject(store)

                // Quick checklist for today
                TodayChecklistCard()
                    .environmentObject(store)

                // Guest arrival tracker
                GuestArrivalCard()
                    .environmentObject(store)

                Spacer(minLength: 20)
            }
            .padding(16)
            .padding(.top, 8)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Day-Of Dashboard")
        .navigationBarTitleDisplayMode(.large)
        .onReceive(timer) { _ in currentTime = Date() }
        .onAppear {
            // Auto-select closest upcoming event
            if selectedEvent == nil {
                selectedEvent = store.upcomingEvents.first
            }
        }
    }
}

// MARK: - Hero Card
struct DayOfHeroCard: View {
    let currentTime: Date
    let wedding: Wedding

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(VivahTheme.gradient)

            VStack(spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(currentTime, style: .date)
                            .font(.caption).foregroundColor(VivahTheme.ivory.opacity(0.7))
                        Text(currentTime, style: .time)
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(VivahTheme.gold)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        if wedding.daysUntilWedding == 0 {
                            Text("Today is the Day!")
                                .font(.headline).fontWeight(.bold)
                                .foregroundColor(VivahTheme.gold)
                        } else if wedding.daysUntilWedding > 0 {
                            VStack(alignment: .trailing) {
                                Text("\(wedding.daysUntilWedding)")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundColor(VivahTheme.ivory)
                                Text("days to wedding")
                                    .font(.caption2)
                                    .foregroundColor(VivahTheme.ivory.opacity(0.7))
                            }
                        } else {
                            Text("Wedding Complete!")
                                .font(.headline).foregroundColor(VivahTheme.gold)
                        }
                    }
                }

                HStack {
                    Label("Coordination Mode Active", systemImage: "sparkles")
                        .font(.caption)
                        .foregroundColor(VivahTheme.gold.opacity(0.8))
                    Spacer()
                    Text("\(wedding.brideName) & \(wedding.groomName)")
                        .font(.caption)
                        .foregroundColor(VivahTheme.ivory.opacity(0.7))
                }
            }
            .padding(20)
        }
        .shadow(color: VivahTheme.deepRed.opacity(0.3), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Event Select Pill
struct EventSelectPill: View {
    let event: WeddingEvent
    let isSelected: Bool
    let action: () -> Void

    var daysUntil: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: event.date).day ?? 0
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Text(event.name)
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundColor(isSelected ? VivahTheme.ivory : .primary)
                HStack(spacing: 4) {
                    Text("\(daysUntil)d away")
                        .font(.caption2)
                        .foregroundColor(isSelected ? VivahTheme.gold : .secondary)
                    if !event.venue.isEmpty {
                        Text("• \(event.venue)")
                            .font(.caption2)
                            .foregroundColor(isSelected ? VivahTheme.ivory.opacity(0.7) : .secondary)
                            .lineLimit(1)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isSelected ? VivahTheme.deepRed : Color(.systemGray6))
            .cornerRadius(12)
        }
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

// MARK: - Today Timeline
struct TodayTimelineCard: View {
    @EnvironmentObject var store: WeddingStore
    let events: [WeddingEvent]
    let currentTime: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Today's Timeline", systemImage: "clock.fill")
                .font(.subheadline).fontWeight(.semibold)
                .foregroundColor(VivahTheme.deepRed)

            ForEach(events) { event in
                let isNow = currentTime >= event.startTime && currentTime <= event.endTime
                HStack(alignment: .top, spacing: 12) {
                    VStack(spacing: 0) {
                        Circle()
                            .fill(isNow ? VivahTheme.gold : VivahTheme.deepRed)
                            .frame(width: 10, height: 10)
                        Rectangle()
                            .fill(VivahTheme.gold.opacity(0.3))
                            .frame(width: 2, height: 40)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(event.name)
                                .font(.subheadline).fontWeight(.semibold)
                            if isNow {
                                Text("NOW")
                                    .font(.caption2).fontWeight(.bold)
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(VivahTheme.gold)
                                    .foregroundColor(VivahTheme.maroon)
                                    .cornerRadius(6)
                            }
                        }
                        Text("\(event.startTime, style: .time) – \(event.endTime, style: .time)")
                            .font(.caption).foregroundColor(.secondary)
                        if !event.venue.isEmpty {
                            Label(event.venue, systemImage: "mappin")
                                .font(.caption2).foregroundColor(.secondary)
                        }
                        Text("\(store.guestsForEvent(event.id).count) guests")
                            .font(.caption2).foregroundColor(.secondary)
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

// MARK: - Event Day-Of Dashboard
struct EventDayOfDashboard: View {
    @EnvironmentObject var store: WeddingStore
    let event: WeddingEvent

    var confirmedGuests: [Guest] {
        store.guestsForEvent(event.id).filter { $0.rsvpStatus == .confirmed }
    }

    var pendingGuests: [Guest] {
        store.guestsForEvent(event.id).filter { $0.rsvpStatus == .pending }
    }

    var vendors: [Vendor] {
        store.vendorsForEvent(event.id).filter { $0.isBooked }
    }

    var body: some View {
        VStack(spacing: 14) {
            // Event header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.name)
                        .font(.title3).fontWeight(.bold)
                        .foregroundColor(VivahTheme.deepRed)
                    HStack(spacing: 8) {
                        Label(event.date, style: .date, icon: "calendar")
                        Label(event.startTime, style: .time, icon: "clock")
                    }
                    .font(.caption).foregroundColor(.secondary)
                    if !event.venue.isEmpty {
                        Label(event.venue, systemImage: "mappin.and.ellipse")
                            .font(.caption).foregroundColor(.secondary)
                    }
                }
                Spacer()
            }
            .padding(14)
            .background(VivahTheme.deepRed.opacity(0.05))
            .cornerRadius(12)

            // Guest status
            HStack(spacing: 10) {
                DayOfStatCard(value: "\(confirmedGuests.count)", label: "Confirmed", icon: "checkmark.circle.fill", color: .green)
                DayOfStatCard(value: "\(pendingGuests.count)", label: "Pending", icon: "questionmark.circle.fill", color: .orange)
                DayOfStatCard(value: "\(vendors.count)", label: "Vendors", icon: "briefcase.fill", color: VivahTheme.gold)
            }

            // Vendor contacts for event
            if !vendors.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Label("Vendor Contacts", systemImage: "phone.fill")
                        .font(.subheadline).fontWeight(.semibold)
                        .foregroundColor(VivahTheme.deepRed)

                    ForEach(vendors) { vendor in
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(VivahTheme.gold.opacity(0.15))
                                    .frame(width: 36, height: 36)
                                Image(systemName: vendor.category.icon)
                                    .font(.caption)
                                    .foregroundColor(VivahTheme.gold)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(vendor.name)
                                    .font(.subheadline).fontWeight(.medium)
                                Text(vendor.contactPerson.isEmpty ? vendor.category.rawValue : vendor.contactPerson)
                                    .font(.caption2).foregroundColor(.secondary)
                            }
                            Spacer()
                            if !vendor.phone.isEmpty {
                                Button(action: {
                                    if let url = URL(string: "tel://\(vendor.phone)") {
                                        UIApplication.shared.open(url)
                                    }
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "phone.fill")
                                            .font(.caption)
                                        Text("Call")
                                            .font(.caption).fontWeight(.semibold)
                                    }
                                    .padding(.horizontal, 12).padding(.vertical, 6)
                                    .background(VivahTheme.forestGreen)
                                    .foregroundColor(.white)
                                    .cornerRadius(16)
                                }
                            }
                        }
                    }
                }
            }

            // Dietary summary
            let dietaryGroups = Dictionary(grouping: confirmedGuests) { $0.dietaryPreference }
            if !dietaryGroups.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Label("Dietary Requirements", systemImage: "fork.knife.circle.fill")
                        .font(.subheadline).fontWeight(.semibold)
                        .foregroundColor(VivahTheme.deepRed)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(DietaryPreference.allCases, id: \.self) { pref in
                            if let guests = dietaryGroups[pref], !guests.isEmpty {
                                HStack {
                                    Text(pref.rawValue)
                                        .font(.caption).fontWeight(.medium)
                                    Spacer()
                                    Text("\(guests.count)")
                                        .font(.caption).fontWeight(.bold)
                                        .foregroundColor(VivahTheme.deepRed)
                                }
                                .padding(10)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                        }
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

struct DayOfStatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
            Text(label)
                .font(.caption2).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(color.opacity(0.08))
        .cornerRadius(12)
    }
}

// MARK: - Emergency Contacts Card
struct EmergencyContactsCard: View {
    @EnvironmentObject var store: WeddingStore

    var vipVendors: [Vendor] {
        store.vendors.filter { $0.isBooked && !$0.phone.isEmpty }.prefix(5).map { $0 }
    }

    var body: some View {
        if !vipVendors.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Label("Quick Dial — Key Vendors", systemImage: "phone.badge.checkmark.fill")
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundColor(VivahTheme.deepRed)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(vipVendors) { vendor in
                        Button(action: {
                            if let url = URL(string: "tel://\(vendor.phone)") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: vendor.category.icon)
                                    .font(.caption)
                                    .foregroundColor(VivahTheme.gold)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(vendor.name)
                                        .font(.caption).fontWeight(.semibold)
                                        .lineLimit(1)
                                    Text(vendor.category.rawValue)
                                        .font(.caption2).foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                                Spacer()
                                Image(systemName: "phone.circle.fill")
                                    .foregroundColor(VivahTheme.forestGreen)
                            }
                            .padding(10)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
        }
    }
}

// MARK: - Today's Checklist
struct TodayChecklistCard: View {
    @EnvironmentObject var store: WeddingStore

    var urgentItems: [ChecklistItem] {
        store.checklistItems.filter {
            !$0.isCompleted && ($0.priority == .urgent || $0.priority == .high)
        }.prefix(5).map { $0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("High Priority Tasks", systemImage: "exclamationmark.triangle.fill")
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundColor(VivahTheme.deepRed)
                Spacer()
                Text("\(store.completedChecklistCount)/\(store.checklistItems.count)")
                    .font(.caption).foregroundColor(.secondary)
            }

            if urgentItems.isEmpty {
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                    Text("All high priority tasks complete!")
                        .font(.subheadline).foregroundColor(.green)
                }
                .padding()
            } else {
                ForEach(urgentItems) { item in
                    HStack(spacing: 12) {
                        Button(action: { store.toggleChecklistItem(item) }) {
                            Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(item.isCompleted ? .green : .secondary)
                                .font(.title3)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title)
                                .font(.subheadline)
                                .strikethrough(item.isCompleted)
                                .foregroundColor(item.isCompleted ? .secondary : .primary)
                            if let due = item.dueDate {
                                Text("Due: \(due, style: .date)")
                                    .font(.caption2)
                                    .foregroundColor(due < Date() ? .red : .secondary)
                            }
                        }
                        Spacer()
                        Circle()
                            .fill(item.priority.color)
                            .frame(width: 8, height: 8)
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

// MARK: - Guest Arrival Tracker
struct GuestArrivalCard: View {
    @EnvironmentObject var store: WeddingStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Guest Status Overview", systemImage: "person.2.fill")
                .font(.subheadline).fontWeight(.semibold)
                .foregroundColor(VivahTheme.deepRed)

            let totalGuests = store.guests.count
            let confirmed = store.confirmedGuestCount
            let pending = store.pendingRSVPCount
            let declined = store.guests.filter { $0.rsvpStatus == .declined }.count

            if totalGuests == 0 {
                Text("No guests added yet.")
                    .font(.subheadline).foregroundColor(.secondary)
            } else {
                // Visual bar
                GeometryReader { geo in
                    HStack(spacing: 2) {
                        Rectangle()
                            .fill(Color.green)
                            .frame(width: geo.size.width * CGFloat(confirmed) / CGFloat(totalGuests))
                        Rectangle()
                            .fill(Color.orange)
                            .frame(width: geo.size.width * CGFloat(pending) / CGFloat(totalGuests))
                        Rectangle()
                            .fill(Color.red)
                            .frame(width: geo.size.width * CGFloat(declined) / CGFloat(totalGuests))
                    }
                    .frame(height: 8)
                    .cornerRadius(4)
                }
                .frame(height: 8)

                HStack {
                    GuestStatusLegend(color: .green, label: "Confirmed", count: confirmed)
                    GuestStatusLegend(color: .orange, label: "Pending", count: pending)
                    GuestStatusLegend(color: .red, label: "Declined", count: declined)
                }

                // VIP guests
                let vipGuests = store.guests.filter { $0.isVIP }
                if !vipGuests.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("VIP Guests (\(vipGuests.count))")
                            .font(.caption).fontWeight(.semibold)
                            .foregroundColor(VivahTheme.gold)
                        ForEach(vipGuests.prefix(3)) { guest in
                            HStack {
                                Image(systemName: "star.fill")
                                    .font(.caption2).foregroundColor(VivahTheme.gold)
                                Text(guest.fullName)
                                    .font(.caption)
                                Spacer()
                                Text(guest.rsvpStatus.rawValue)
                                    .font(.caption2).foregroundColor(guest.rsvpStatus.color)
                            }
                        }
                    }
                    .padding(10)
                    .background(VivahTheme.gold.opacity(0.05))
                    .cornerRadius(10)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
    }
}

struct GuestStatusLegend: View {
    let color: Color
    let label: String
    let count: Int

    var body: some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text("\(count) \(label)")
                .font(.caption2).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
