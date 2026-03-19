import Foundation
import SwiftUI
import Combine

class WeddingStore: ObservableObject {
    // MARK: - Published Properties
    @Published var wedding: Wedding = Wedding()
    @Published var events: [WeddingEvent] = []
    @Published var guests: [Guest] = []
    @Published var households: [Household] = []
    @Published var vendors: [Vendor] = []
    @Published var budgetItems: [BudgetItem] = []
    @Published var shagunEntries: [ShagunEntry] = []
    @Published var checklistItems: [ChecklistItem] = []
    @Published var isOnboardingComplete: Bool = false

    // MARK: - UserDefaults Keys
    private let weddingKey = "vivah_wedding"
    private let eventsKey = "vivah_events"
    private let guestsKey = "vivah_guests"
    private let householdsKey = "vivah_households"
    private let vendorsKey = "vivah_vendors"
    private let budgetKey = "vivah_budget"
    private let shagunKey = "vivah_shagun"
    private let checklistKey = "vivah_checklist"
    private let onboardingKey = "vivah_onboarding_complete"

    init() {
        loadAll()
    }

    // MARK: - Computed Properties

    var totalBudgetSpent: Double {
        budgetItems.reduce(0) { $0 + $1.actualAmount }
    }

    var totalBudgetEstimated: Double {
        budgetItems.reduce(0) { $0 + $1.estimatedAmount }
    }

    var totalPaid: Double {
        budgetItems.reduce(0) { $0 + $1.paidAmount }
    }

    var budgetRemaining: Double {
        wedding.totalBudget - totalBudgetSpent
    }

    var confirmedGuestCount: Int {
        guests.filter { $0.rsvpStatus == .confirmed }.count
    }

    var pendingRSVPCount: Int {
        guests.filter { $0.rsvpStatus == .pending }.count
    }

    var totalShagunAmount: Double {
        shagunEntries.reduce(0) { $0 + $1.amount }
    }

    var completedChecklistCount: Int {
        checklistItems.filter { $0.isCompleted }.count
    }

    var upcomingEvents: [WeddingEvent] {
        events.filter { $0.date >= Date() }.sorted { $0.date < $1.date }
    }

    var overdueChecklistItems: [ChecklistItem] {
        checklistItems.filter {
            !$0.isCompleted &&
            $0.dueDate != nil &&
            $0.dueDate! < Date()
        }
    }

    var brideFamilySpend: Double {
        budgetItems.filter { $0.paidBy == .bride }.reduce(0) { $0 + $1.paidAmount }
    }

    var groomFamilySpend: Double {
        budgetItems.filter { $0.paidBy == .groom }.reduce(0) { $0 + $1.paidAmount }
    }

    var vendorsBooked: Int {
        vendors.filter { $0.isBooked }.count
    }

    var totalVendorBalance: Double {
        vendors.filter { $0.isBooked }.reduce(0) { $0 + $1.balanceDue }
    }

    // MARK: - Wedding Methods

    func saveWedding() {
        if let encoded = try? JSONEncoder().encode(wedding) {
            UserDefaults.standard.set(encoded, forKey: weddingKey)
        }
    }

    func updateWedding(_ updated: Wedding) {
        wedding = updated
        saveWedding()
    }

    // MARK: - Event Methods

    func addEvent(_ event: WeddingEvent) {
        events.append(event)
        events.sort { $0.date < $1.date }
        saveEvents()
    }

    func updateEvent(_ event: WeddingEvent) {
        if let index = events.firstIndex(where: { $0.id == event.id }) {
            events[index] = event
            saveEvents()
        }
    }

    func deleteEvent(_ event: WeddingEvent) {
        events.removeAll { $0.id == event.id }
        saveEvents()
    }

    func guestsForEvent(_ eventId: UUID) -> [Guest] {
        guests.filter { $0.eventsAttending.contains(eventId) }
    }

    func vendorsForEvent(_ eventId: UUID) -> [Vendor] {
        vendors.filter { $0.assignedEvents.contains(eventId) }
    }

    // MARK: - Guest Methods

    func addGuest(_ guest: Guest) {
        guests.append(guest)
        saveGuests()
    }

    func updateGuest(_ guest: Guest) {
        if let index = guests.firstIndex(where: { $0.id == guest.id }) {
            guests[index] = guest
            saveGuests()
        }
    }

    func deleteGuest(_ guest: Guest) {
        guests.removeAll { $0.id == guest.id }
        saveGuests()
    }

    func guestsInHousehold(_ householdId: UUID) -> [Guest] {
        guests.filter { $0.householdId == householdId }
    }

    // MARK: - Household Methods

    func addHousehold(_ household: Household) {
        households.append(household)
        saveHouseholds()
    }

    func updateHousehold(_ household: Household) {
        if let index = households.firstIndex(where: { $0.id == household.id }) {
            households[index] = household
            saveHouseholds()
        }
    }

    func deleteHousehold(_ household: Household) {
        households.removeAll { $0.id == household.id }
        saveHouseholds()
    }

    // MARK: - Vendor Methods

    func addVendor(_ vendor: Vendor) {
        vendors.append(vendor)
        saveVendors()
    }

    func updateVendor(_ vendor: Vendor) {
        if let index = vendors.firstIndex(where: { $0.id == vendor.id }) {
            vendors[index] = vendor
            saveVendors()
        }
    }

    func deleteVendor(_ vendor: Vendor) {
        vendors.removeAll { $0.id == vendor.id }
        saveVendors()
    }

    // MARK: - Budget Methods

    func addBudgetItem(_ item: BudgetItem) {
        budgetItems.append(item)
        saveBudget()
    }

    func updateBudgetItem(_ item: BudgetItem) {
        if let index = budgetItems.firstIndex(where: { $0.id == item.id }) {
            budgetItems[index] = item
            saveBudget()
        }
    }

    func deleteBudgetItem(_ item: BudgetItem) {
        budgetItems.removeAll { $0.id == item.id }
        saveBudget()
    }

    func budgetItemsForEvent(_ eventId: UUID) -> [BudgetItem] {
        budgetItems.filter { $0.eventId == eventId }
    }

    func totalSpendForEvent(_ eventId: UUID) -> Double {
        budgetItemsForEvent(eventId).reduce(0) { $0 + $1.actualAmount }
    }

    // MARK: - Shagun Methods

    func addShagunEntry(_ entry: ShagunEntry) {
        shagunEntries.append(entry)
        saveShagun()
    }

    func updateShagunEntry(_ entry: ShagunEntry) {
        if let index = shagunEntries.firstIndex(where: { $0.id == entry.id }) {
            shagunEntries[index] = entry
            saveShagun()
        }
    }

    func deleteShagunEntry(_ entry: ShagunEntry) {
        shagunEntries.removeAll { $0.id == entry.id }
        saveShagun()
    }

    // MARK: - Checklist Methods

    func addChecklistItem(_ item: ChecklistItem) {
        checklistItems.append(item)
        saveChecklist()
    }

    func updateChecklistItem(_ item: ChecklistItem) {
        if let index = checklistItems.firstIndex(where: { $0.id == item.id }) {
            checklistItems[index] = item
            saveChecklist()
        }
    }

    func toggleChecklistItem(_ item: ChecklistItem) {
        if let index = checklistItems.firstIndex(where: { $0.id == item.id }) {
            checklistItems[index].isCompleted.toggle()
            if checklistItems[index].isCompleted {
                checklistItems[index].completedDate = Date()
            } else {
                checklistItems[index].completedDate = nil
            }
            saveChecklist()
        }
    }

    func deleteChecklistItem(_ item: ChecklistItem) {
        checklistItems.removeAll { $0.id == item.id }
        saveChecklist()
    }

    // MARK: - Onboarding Setup

    func completeOnboarding(wedding: Wedding, events: [WeddingEvent], checklist: [ChecklistItem]) {
        self.wedding = wedding
        self.events = events
        self.checklistItems = checklist
        self.isOnboardingComplete = true
        UserDefaults.standard.set(true, forKey: onboardingKey)
        saveAll()
    }

    func generateDefaultChecklist(for religion: Religion) -> [ChecklistItem] {
        var items: [ChecklistItem] = []
        let tasks = religion.defaultChecklist
        let now = Date()
        let weddingDate = wedding.weddingDate

        for (i, task) in tasks.enumerated() {
            let daysBeforeWedding = Double((tasks.count - i) * 14)
            let dueDate = weddingDate.addingTimeInterval(-daysBeforeWedding * 86400)
            let item = ChecklistItem(
                title: task,
                category: "Ceremony",
                dueDate: dueDate < now ? now.addingTimeInterval(86400 * 7) : dueDate,
                assignedTo: i % 2 == 0 ? .bride : .groom,
                priority: i < 3 ? .high : .medium
            )
            items.append(item)
        }

        // Add common checklist items
        let commonTasks: [(String, Int, ChecklistItem.Priority)] = [
            ("Book venue for all ceremonies", 180, .urgent),
            ("Send save-the-dates", 120, .high),
            ("Book photographer", 150, .urgent),
            ("Book videographer", 150, .high),
            ("Book caterer", 120, .urgent),
            ("Order wedding cards/invitations", 90, .high),
            ("Book travel & accommodation for out-of-station guests", 60, .medium),
            ("Order bride's lehenga/outfit", 120, .high),
            ("Order groom's sherwani/outfit", 90, .high),
            ("Book makeup artist for bride", 90, .high),
            ("Confirm RSVP count with caterer", 14, .urgent),
            ("Prepare welcome bags for guests", 30, .medium),
            ("Arrange trousseau items", 60, .medium),
            ("Book honeymoon travel", 90, .medium),
            ("Purchase wedding rings", 60, .high),
        ]

        for (task, daysBefore, priority) in commonTasks {
            let dueDate = weddingDate.addingTimeInterval(-Double(daysBefore) * 86400)
            let item = ChecklistItem(
                title: task,
                category: "General",
                dueDate: dueDate < now ? now.addingTimeInterval(86400 * 7) : dueDate,
                assignedTo: .shared,
                priority: priority
            )
            items.append(item)
        }

        return items
    }

    func generateDefaultEvents(for religion: Religion, weddingDate: Date) -> [WeddingEvent] {
        let eventNames = religion.defaultEvents
        var events: [WeddingEvent] = []
        let calendar = Calendar.current

        let eventColors = ["deepRed", "gold", "marigold", "green", "purple", "saffron", "rose"]

        for (i, name) in eventNames.enumerated() {
            let daysOffset = i - (eventNames.count - 1)
            var components = DateComponents()
            components.day = daysOffset
            let eventDate = calendar.date(byAdding: components, to: weddingDate) ?? weddingDate

            var event = WeddingEvent(name: name)
            event.date = eventDate
            event.color = eventColors[i % eventColors.count]
            events.append(event)
        }

        return events
    }

    // MARK: - WhatsApp RSVP
    func generateWhatsAppRSVPLink(for guest: Guest, eventNames: [String]) -> String {
        let message = "Hi \(guest.firstName)! You're invited to \(wedding.brideName) & \(wedding.groomName)'s wedding celebrations. Events: \(eventNames.joined(separator: ", ")). Please confirm your attendance by replying YES or NO."
        let encoded = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let phone = guest.phone.replacingOccurrences(of: "+", with: "").replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "-", with: "")
        return "https://wa.me/\(phone)?text=\(encoded)"
    }

    // MARK: - Persistence

    private func saveAll() {
        saveWedding()
        saveEvents()
        saveGuests()
        saveHouseholds()
        saveVendors()
        saveBudget()
        saveShagun()
        saveChecklist()
    }

    private func saveEvents() {
        if let encoded = try? JSONEncoder().encode(events) {
            UserDefaults.standard.set(encoded, forKey: eventsKey)
        }
    }

    private func saveGuests() {
        if let encoded = try? JSONEncoder().encode(guests) {
            UserDefaults.standard.set(encoded, forKey: guestsKey)
        }
    }

    private func saveHouseholds() {
        if let encoded = try? JSONEncoder().encode(households) {
            UserDefaults.standard.set(encoded, forKey: householdsKey)
        }
    }

    private func saveVendors() {
        if let encoded = try? JSONEncoder().encode(vendors) {
            UserDefaults.standard.set(encoded, forKey: vendorsKey)
        }
    }

    private func saveBudget() {
        if let encoded = try? JSONEncoder().encode(budgetItems) {
            UserDefaults.standard.set(encoded, forKey: budgetKey)
        }
    }

    private func saveShagun() {
        if let encoded = try? JSONEncoder().encode(shagunEntries) {
            UserDefaults.standard.set(encoded, forKey: shagunKey)
        }
    }

    private func saveChecklist() {
        if let encoded = try? JSONEncoder().encode(checklistItems) {
            UserDefaults.standard.set(encoded, forKey: checklistKey)
        }
    }

    private func loadAll() {
        isOnboardingComplete = UserDefaults.standard.bool(forKey: onboardingKey)

        if let data = UserDefaults.standard.data(forKey: weddingKey),
           let decoded = try? JSONDecoder().decode(Wedding.self, from: data) {
            wedding = decoded
        }
        if let data = UserDefaults.standard.data(forKey: eventsKey),
           let decoded = try? JSONDecoder().decode([WeddingEvent].self, from: data) {
            events = decoded
        }
        if let data = UserDefaults.standard.data(forKey: guestsKey),
           let decoded = try? JSONDecoder().decode([Guest].self, from: data) {
            guests = decoded
        }
        if let data = UserDefaults.standard.data(forKey: householdsKey),
           let decoded = try? JSONDecoder().decode([Household].self, from: data) {
            households = decoded
        }
        if let data = UserDefaults.standard.data(forKey: vendorsKey),
           let decoded = try? JSONDecoder().decode([Vendor].self, from: data) {
            vendors = decoded
        }
        if let data = UserDefaults.standard.data(forKey: budgetKey),
           let decoded = try? JSONDecoder().decode([BudgetItem].self, from: data) {
            budgetItems = decoded
        }
        if let data = UserDefaults.standard.data(forKey: shagunKey),
           let decoded = try? JSONDecoder().decode([ShagunEntry].self, from: data) {
            shagunEntries = decoded
        }
        if let data = UserDefaults.standard.data(forKey: checklistKey),
           let decoded = try? JSONDecoder().decode([ChecklistItem].self, from: data) {
            checklistItems = decoded
        }
    }

    // MARK: - Reset (for testing)
    func resetAll() {
        let keys = [weddingKey, eventsKey, guestsKey, householdsKey, vendorsKey, budgetKey, shagunKey, checklistKey, onboardingKey]
        keys.forEach { UserDefaults.standard.removeObject(forKey: $0) }
        wedding = Wedding()
        events = []
        guests = []
        households = []
        vendors = []
        budgetItems = []
        shagunEntries = []
        checklistItems = []
        isOnboardingComplete = false
    }
}
