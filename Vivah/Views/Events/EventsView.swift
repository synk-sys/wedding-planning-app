import SwiftUI

struct EventsView: View {
    @EnvironmentObject var store: WeddingStore
    @State private var showAddEvent = false
    @State private var selectedFilter: EventFilter = .all

    enum EventFilter: String, CaseIterable {
        case all = "All"
        case upcoming = "Upcoming"
        case completed = "Completed"
    }

    var filteredEvents: [WeddingEvent] {
        let sorted = store.events.sorted { $0.date < $1.date }
        switch selectedFilter {
        case .all: return sorted
        case .upcoming: return sorted.filter { $0.date >= Date() }
        case .completed: return sorted.filter { $0.date < Date() || $0.isCompleted }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter Pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(EventFilter.allCases, id: \.self) { filter in
                            FilterChip(
                                title: filter.rawValue,
                                isSelected: selectedFilter == filter,
                                action: { selectedFilter = filter }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
                .background(Color(.systemBackground))

                if filteredEvents.isEmpty {
                    EmptyStateView(
                        icon: "calendar.badge.plus",
                        title: "No Events Yet",
                        subtitle: "Tap + to add your first ceremony"
                    )
                } else {
                    ScrollView {
                        // Timeline view
                        VStack(spacing: 0) {
                            ForEach(Array(filteredEvents.enumerated()), id: \.element.id) { index, event in
                                NavigationLink {
                                    EventDetailView(event: event)
                                        .environmentObject(store)
                                } label: {
                                    EventTimelineRow(
                                        event: event,
                                        isFirst: index == 0,
                                        isLast: index == filteredEvents.count - 1
                                    )
                                    .environmentObject(store)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 20)
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Events")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddEvent = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(VivahTheme.deepRed)
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showAddEvent) {
                AddEventView()
                    .environmentObject(store)
            }
        }
    }
}

// MARK: - Timeline Row
struct EventTimelineRow: View {
    @EnvironmentObject var store: WeddingStore
    let event: WeddingEvent
    let isFirst: Bool
    let isLast: Bool

    var isPast: Bool { event.date < Date() }
    var guestCount: Int { store.guestsForEvent(event.id).count }
    var vendorCount: Int { store.vendorsForEvent(event.id).count }
    var budget: Double { store.totalSpendForEvent(event.id) }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // Timeline
            VStack(spacing: 0) {
                if !isFirst {
                    Rectangle()
                        .fill(VivahTheme.gold.opacity(0.3))
                        .frame(width: 2, height: 20)
                } else {
                    Spacer().frame(height: 20)
                }

                ZStack {
                    Circle()
                        .fill(isPast ? Color(.systemGray4) : VivahTheme.deepRed)
                        .frame(width: 14, height: 14)
                    if event.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundColor(.white)
                    }
                }

                if !isLast {
                    Rectangle()
                        .fill(VivahTheme.gold.opacity(0.3))
                        .frame(width: 2)
                }
            }
            .frame(width: 14)

            // Event Card
            VStack(alignment: .leading, spacing: 0) {
                Spacer().frame(height: 14)

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(event.name)
                                .font(.headline)
                                .foregroundColor(isPast ? .secondary : .primary)
                            HStack(spacing: 6) {
                                Text(event.date, style: .date)
                                    .font(.caption)
                                    .foregroundColor(isPast ? .secondary : VivahTheme.deepRed)
                                Text("•")
                                    .font(.caption).foregroundColor(.secondary)
                                Text(event.startTime, style: .time)
                                    .font(.caption).foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        if isPast {
                            Text("Done")
                                .font(.caption2).fontWeight(.medium)
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(Color(.systemGray5))
                                .foregroundColor(.secondary)
                                .cornerRadius(6)
                        } else {
                            let days = Calendar.current.dateComponents([.day], from: Date(), to: event.date).day ?? 0
                            Text("\(days)d away")
                                .font(.caption2).fontWeight(.semibold)
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(VivahTheme.gold.opacity(0.15))
                                .foregroundColor(VivahTheme.deepRed)
                                .cornerRadius(6)
                        }
                    }

                    if !event.venue.isEmpty {
                        Label(event.venue, systemImage: "mappin.and.ellipse")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    HStack(spacing: 16) {
                        EventStatChip(icon: "person.2", value: "\(guestCount)", label: "Guests")
                        EventStatChip(icon: "briefcase", value: "\(vendorCount)", label: "Vendors")
                        if budget > 0 {
                            EventStatChip(icon: "indianrupeesign", value: budget.inrShortFormatted, label: "Spent")
                        }
                        if !event.dressCode.isEmpty {
                            EventStatChip(icon: "tshirt", value: event.dressCode, label: "Dress Code")
                        }
                    }
                }
                .padding(14)
                .background(Color(.systemBackground))
                .cornerRadius(14)
                .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
                .opacity(isPast ? 0.7 : 1)

                Spacer().frame(height: 8)
            }
        }
    }
}

struct EventStatChip: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(VivahTheme.gold)
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.caption).fontWeight(.semibold)
                Text(label)
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline).fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16).padding(.vertical, 7)
                .background(isSelected ? VivahTheme.deepRed : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

// MARK: - Empty State
struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 50))
                .foregroundColor(VivahTheme.gold.opacity(0.6))
            Text(title)
                .font(.title3).fontWeight(.semibold)
            Text(subtitle)
                .font(.subheadline).foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

// MARK: - Add Event View
struct AddEventView: View {
    @EnvironmentObject var store: WeddingStore
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var date = Date()
    @State private var startTime = Date()
    @State private var endTime = Date().addingTimeInterval(4 * 3600)
    @State private var venue = ""
    @State private var venueAddress = ""
    @State private var guestCapacity = 100
    @State private var dressCode = ""
    @State private var estimatedBudget = ""
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Event Details") {
                    TextField("Event Name (e.g. Haldi, Mehndi)", text: $name)
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    DatePicker("Start Time", selection: $startTime, displayedComponents: .hourAndMinute)
                    DatePicker("End Time", selection: $endTime, displayedComponents: .hourAndMinute)
                }

                Section("Venue") {
                    TextField("Venue Name", text: $venue)
                    TextField("Venue Address", text: $venueAddress)
                    Stepper("Guest Capacity: \(guestCapacity)", value: $guestCapacity, in: 10...5000, step: 10)
                }

                Section("Details") {
                    TextField("Dress Code", text: $dressCode)
                    TextField("Estimated Budget (₹)", text: $estimatedBudget)
                        .keyboardType(.numberPad)
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                // Quick event names
                Section("Quick Add") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(store.wedding.religion.defaultEvents, id: \.self) { eventName in
                                Button(eventName) { name = eventName }
                                    .font(.caption)
                                    .padding(.horizontal, 12).padding(.vertical, 6)
                                    .background(name == eventName ? VivahTheme.deepRed : Color(.systemGray5))
                                    .foregroundColor(name == eventName ? .white : .primary)
                                    .cornerRadius(16)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Add Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { saveEvent() }
                        .disabled(name.isEmpty)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    func saveEvent() {
        var event = WeddingEvent(name: name)
        event.date = date
        event.startTime = startTime
        event.endTime = endTime
        event.venue = venue
        event.venueAddress = venueAddress
        event.guestCapacity = guestCapacity
        event.dressCode = dressCode
        event.estimatedBudget = Double(estimatedBudget) ?? 0
        event.notes = notes
        store.addEvent(event)
        dismiss()
    }
}
