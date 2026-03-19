import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var store: WeddingStore
    @State private var showEditWedding = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Hero Card
                    HeroCountdownCard()
                        .environmentObject(store)

                    // Quick Stats Row
                    QuickStatsRow()
                        .environmentObject(store)

                    // Upcoming Events
                    if !store.upcomingEvents.isEmpty {
                        UpcomingEventsSection()
                            .environmentObject(store)
                    }

                    // Budget Overview
                    BudgetOverviewCard()
                        .environmentObject(store)

                    // Overdue Tasks
                    if !store.overdueChecklistItems.isEmpty {
                        OverdueTasksCard()
                            .environmentObject(store)
                    }

                    // Vendor Payments Due
                    VendorPaymentsCard()
                        .environmentObject(store)

                    // Guest RSVP Summary
                    GuestRSVPCard()
                        .environmentObject(store)

                    // Shagun Summary
                    ShagunSummaryCard()
                        .environmentObject(store)

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("विवाह").font(.system(size: 22, weight: .bold, design: .serif))
                            .foregroundColor(VivahTheme.deepRed)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showEditWedding = true }) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(VivahTheme.deepRed)
                    }
                }
            }
            .sheet(isPresented: $showEditWedding) {
                EditWeddingView()
                    .environmentObject(store)
            }
        }
    }
}

// MARK: - Hero Countdown Card
struct HeroCountdownCard: View {
    @EnvironmentObject var store: WeddingStore

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(VivahTheme.gradient)

            VStack(spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(store.wedding.brideName) & \(store.wedding.groomName)")
                            .font(.system(size: 22, weight: .bold, design: .serif))
                            .foregroundColor(VivahTheme.ivory)
                        Text(store.wedding.religion.rawValue)
                            .font(.caption)
                            .foregroundColor(VivahTheme.gold.opacity(0.9))
                        if !store.wedding.city.isEmpty {
                            Label(store.wedding.city, systemImage: "location.fill")
                                .font(.caption)
                                .foregroundColor(VivahTheme.ivory.opacity(0.7))
                        }
                    }
                    Spacer()
                    VStack(spacing: 4) {
                        Text("\(store.wedding.daysUntilWedding)")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundColor(VivahTheme.gold)
                        Text("days to go")
                            .font(.caption2)
                            .foregroundColor(VivahTheme.ivory.opacity(0.8))
                    }
                }

                Divider().background(VivahTheme.ivory.opacity(0.2))

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Wedding Date")
                            .font(.caption2).foregroundColor(VivahTheme.ivory.opacity(0.6))
                        Text(store.wedding.weddingDate, style: .date)
                            .font(.subheadline).fontWeight(.semibold)
                            .foregroundColor(VivahTheme.ivory)
                    }
                    Spacer()
                    if !store.wedding.venue.isEmpty {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Venue")
                                .font(.caption2).foregroundColor(VivahTheme.ivory.opacity(0.6))
                            Text(store.wedding.venue)
                                .font(.subheadline).fontWeight(.semibold)
                                .foregroundColor(VivahTheme.ivory)
                                .lineLimit(1)
                        }
                    }
                }
            }
            .padding(20)
        }
        .shadow(color: VivahTheme.deepRed.opacity(0.3), radius: 12, x: 0, y: 6)
    }
}

// MARK: - Quick Stats
struct QuickStatsRow: View {
    @EnvironmentObject var store: WeddingStore

    var body: some View {
        HStack(spacing: 12) {
            QuickStatCard(
                value: "\(store.events.count)",
                label: "Events",
                icon: "calendar",
                color: VivahTheme.marigold
            )
            QuickStatCard(
                value: "\(store.guests.count)",
                label: "Guests",
                icon: "person.2.fill",
                color: VivahTheme.deepRed
            )
            QuickStatCard(
                value: "\(store.vendorsBooked)",
                label: "Vendors",
                icon: "briefcase.fill",
                color: VivahTheme.gold
            )
            QuickStatCard(
                value: "\(store.completedChecklistCount)",
                label: "Tasks Done",
                icon: "checkmark.circle.fill",
                color: VivahTheme.forestGreen
            )
        }
    }
}

struct QuickStatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Upcoming Events Section
struct UpcomingEventsSection: View {
    @EnvironmentObject var store: WeddingStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Upcoming Events", icon: "calendar.badge.clock")

            ForEach(store.upcomingEvents.prefix(3)) { event in
                UpcomingEventRow(event: event)
                    .environmentObject(store)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
    }
}

struct UpcomingEventRow: View {
    @EnvironmentObject var store: WeddingStore
    let event: WeddingEvent

    var daysUntil: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: event.date).day ?? 0
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(VivahTheme.gold.opacity(0.2))
                    .frame(width: 44, height: 44)
                VStack(spacing: 1) {
                    Text("\(Calendar.current.component(.day, from: event.date))")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(VivahTheme.deepRed)
                    Text(monthAbbrev(event.date))
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(VivahTheme.gold)
                        .textCase(.uppercase)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(event.name)
                    .font(.subheadline).fontWeight(.semibold)
                HStack(spacing: 4) {
                    if !event.venue.isEmpty {
                        Label(event.venue, systemImage: "mappin")
                            .font(.caption).foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                Text("\(store.guestsForEvent(event.id).count) guests expected")
                    .font(.caption2).foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(daysUntil)d")
                    .font(.caption).fontWeight(.semibold)
                    .foregroundColor(daysUntil < 7 ? .red : VivahTheme.deepRed)
                Text("away")
                    .font(.caption2).foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    func monthAbbrev(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "MMM"
        return f.string(from: date)
    }
}

// MARK: - Budget Overview Card
struct BudgetOverviewCard: View {
    @EnvironmentObject var store: WeddingStore

    var spentPercent: Double {
        guard store.wedding.totalBudget > 0 else { return 0 }
        return min(store.totalBudgetSpent / store.wedding.totalBudget, 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Budget Overview", icon: "indianrupeesign.circle.fill")

            // Main budget bar
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Total Budget")
                        .font(.caption).foregroundColor(.secondary)
                    Spacer()
                    Text(store.wedding.totalBudget.inrShortFormatted)
                        .font(.subheadline).fontWeight(.bold)
                }
                ProgressView(value: spentPercent)
                    .tint(spentPercent > 0.9 ? .red : VivahTheme.deepRed)
                    .scaleEffect(x: 1, y: 2, anchor: .center)
                HStack {
                    Text("Spent: \(store.totalBudgetSpent.inrShortFormatted)")
                        .font(.caption).foregroundColor(VivahTheme.deepRed)
                    Spacer()
                    Text("Left: \(store.budgetRemaining.inrShortFormatted)")
                        .font(.caption).foregroundColor(VivahTheme.forestGreen)
                }
            }

            Divider()

            // Family split
            HStack(spacing: 16) {
                FamilyBudgetPill(
                    name: "Bride's Family",
                    amount: store.brideFamilySpend,
                    color: VivahTheme.deepRed
                )
                FamilyBudgetPill(
                    name: "Groom's Family",
                    amount: store.groomFamilySpend,
                    color: VivahTheme.gold
                )
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
    }
}

struct FamilyBudgetPill: View {
    let name: String
    let amount: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name)
                .font(.caption2).foregroundColor(.secondary)
            Text(amount.inrShortFormatted)
                .font(.subheadline).fontWeight(.bold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(color.opacity(0.08))
        .cornerRadius(10)
    }
}

// MARK: - Overdue Tasks Card
struct OverdueTasksCard: View {
    @EnvironmentObject var store: WeddingStore

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Overdue Tasks")
                    .font(.subheadline).fontWeight(.semibold)
                Spacer()
                Text("\(store.overdueChecklistItems.count)")
                    .font(.caption).fontWeight(.bold)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Color.orange.opacity(0.2))
                    .foregroundColor(.orange)
                    .cornerRadius(8)
            }

            ForEach(store.overdueChecklistItems.prefix(3)) { item in
                HStack {
                    Circle()
                        .fill(item.priority.color)
                        .frame(width: 8, height: 8)
                    Text(item.title)
                        .font(.caption)
                        .lineLimit(1)
                    Spacer()
                    if let due = item.dueDate {
                        Text(due, style: .date)
                            .font(.caption2).foregroundColor(.red)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Vendor Payments Card
struct VendorPaymentsCard: View {
    @EnvironmentObject var store: WeddingStore

    var vendorsWithBalance: [Vendor] {
        store.vendors.filter { $0.isBooked && $0.balanceDue > 0 }
    }

    var body: some View {
        if !vendorsWithBalance.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Vendor Payments Due", icon: "creditcard.fill")

                ForEach(vendorsWithBalance.prefix(3)) { vendor in
                    HStack {
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
                                .lineLimit(1)
                            Text(vendor.category.rawValue)
                                .font(.caption2).foregroundColor(.secondary)
                        }
                        Spacer()
                        Text(vendor.balanceDue.inrShortFormatted)
                            .font(.subheadline).fontWeight(.bold)
                            .foregroundColor(VivahTheme.deepRed)
                    }
                }

                if vendorsWithBalance.count > 3 {
                    Text("+ \(vendorsWithBalance.count - 3) more vendors")
                        .font(.caption).foregroundColor(VivahTheme.gold)
                }
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
        }
    }
}

// MARK: - Guest RSVP Card
struct GuestRSVPCard: View {
    @EnvironmentObject var store: WeddingStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Guest RSVPs", icon: "person.2.fill")

            HStack(spacing: 10) {
                RSVPCountPill(count: store.confirmedGuestCount, label: "Confirmed", color: .green)
                RSVPCountPill(count: store.pendingRSVPCount, label: "Pending", color: .orange)
                RSVPCountPill(count: store.guests.filter { $0.rsvpStatus == .declined }.count, label: "Declined", color: .red)
                RSVPCountPill(count: store.guests.count, label: "Total", color: VivahTheme.deepRed)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
    }
}

struct RSVPCountPill: View {
    let count: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

// MARK: - Shagun Summary Card
struct ShagunSummaryCard: View {
    @EnvironmentObject var store: WeddingStore

    var body: some View {
        if !store.shagunEntries.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Shagun & Gifts", icon: "gift.fill")

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total Received")
                            .font(.caption).foregroundColor(.secondary)
                        Text(store.totalShagunAmount.inrFormatted)
                            .font(.title3).fontWeight(.bold)
                            .foregroundColor(VivahTheme.deepRed)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Thank You Pending")
                            .font(.caption).foregroundColor(.secondary)
                        Text("\(store.shagunEntries.filter { !$0.thankYouSent }.count)")
                            .font(.title3).fontWeight(.bold)
                            .foregroundColor(.orange)
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

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        Label(title, systemImage: icon)
            .font(.subheadline).fontWeight(.semibold)
            .foregroundColor(VivahTheme.deepRed)
    }
}

// MARK: - Edit Wedding View
struct EditWeddingView: View {
    @EnvironmentObject var store: WeddingStore
    @Environment(\.dismiss) var dismiss
    @State private var wedding: Wedding = Wedding()

    var body: some View {
        NavigationStack {
            Form {
                Section("Couple") {
                    TextField("Bride's Name", text: $wedding.brideName)
                    TextField("Groom's Name", text: $wedding.groomName)
                }
                Section("Date & Venue") {
                    DatePicker("Wedding Date", selection: $wedding.weddingDate, displayedComponents: .date)
                    TextField("Venue", text: $wedding.venue)
                    TextField("City", text: $wedding.city)
                }
                Section("Budget") {
                    HStack {
                        Text("Total Budget")
                        Spacer()
                        TextField("Amount", value: $wedding.totalBudget, format: .number)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.numberPad)
                    }
                }
                Section("Tradition") {
                    Picker("Religion / Tradition", selection: $wedding.religion) {
                        ForEach(Religion.allCases, id: \.self) { r in
                            Text(r.rawValue).tag(r)
                        }
                    }
                }
                Section {
                    Button("Reset App Data", role: .destructive) {
                        store.resetAll()
                        dismiss()
                    }
                }
            }
            .navigationTitle("Wedding Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.updateWedding(wedding)
                        dismiss()
                    }
                }
            }
        }
        .onAppear { wedding = store.wedding }
    }
}
