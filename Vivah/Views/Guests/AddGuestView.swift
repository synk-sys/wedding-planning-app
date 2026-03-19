import SwiftUI

struct AddGuestView: View {
    @EnvironmentObject var store: WeddingStore
    @Environment(\.dismiss) var dismiss

    var editGuest: Guest? = nil

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var phone = ""
    @State private var email = ""
    @State private var city = ""
    @State private var relationship = ""
    @State private var relationshipSide: RelationshipSide = .brideSide
    @State private var dietaryPreference: DietaryPreference = .vegetarian
    @State private var rsvpStatus: RSVPStatus = .pending
    @State private var selectedHouseholdId: UUID? = nil
    @State private var selectedEventIds: Set<UUID> = []
    @State private var plusOne = false
    @State private var plusOneName = ""
    @State private var tableNumber = ""
    @State private var isVIP = false
    @State private var whatsappOptIn = true
    @State private var notes = ""

    var isEditing: Bool { editGuest != nil }

    var title: String { isEditing ? "Edit Guest" : "Add Guest" }

    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Info") {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                    TextField("Phone Number", text: $phone)
                        .keyboardType(.phonePad)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                    TextField("City", text: $city)
                }

                Section("Relationship") {
                    Picker("Side", selection: $relationshipSide) {
                        ForEach(RelationshipSide.allCases, id: \.self) { side in
                            Text(side.rawValue).tag(side)
                        }
                    }
                    TextField("Relationship (e.g. Maasi, Chacha, Friend)", text: $relationship)

                    if !store.households.isEmpty {
                        Picker("Household", selection: $selectedHouseholdId) {
                            Text("No Household").tag(nil as UUID?)
                            ForEach(store.households.filter {
                                $0.relationshipSide == relationshipSide
                            }) { household in
                                Text(household.familyName).tag(household.id as UUID?)
                            }
                        }
                    }
                }

                Section("Events Attending") {
                    if store.events.isEmpty {
                        Text("No events created yet")
                            .font(.subheadline).foregroundColor(.secondary)
                    } else {
                        ForEach(store.events) { event in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(event.name)
                                        .font(.subheadline).fontWeight(.medium)
                                    Text(event.date, style: .date)
                                        .font(.caption).foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: selectedEventIds.contains(event.id) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(selectedEventIds.contains(event.id) ? VivahTheme.deepRed : .secondary)
                                    .font(.title3)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if selectedEventIds.contains(event.id) {
                                    selectedEventIds.remove(event.id)
                                } else {
                                    selectedEventIds.insert(event.id)
                                }
                            }
                        }
                        HStack {
                            Button("Select All") {
                                selectedEventIds = Set(store.events.map { $0.id })
                            }
                            .font(.caption)
                            Spacer()
                            Button("Clear All") {
                                selectedEventIds = []
                            }
                            .font(.caption)
                            .foregroundColor(.red)
                        }
                    }
                }

                Section("Preferences") {
                    Picker("Dietary Preference", selection: $dietaryPreference) {
                        ForEach(DietaryPreference.allCases, id: \.self) { pref in
                            Text(pref.rawValue).tag(pref)
                        }
                    }
                    Picker("RSVP Status", selection: $rsvpStatus) {
                        ForEach(RSVPStatus.allCases, id: \.self) { status in
                            Text(status.rawValue).tag(status)
                        }
                    }
                }

                Section("Plus One") {
                    Toggle("Has Plus One", isOn: $plusOne)
                    if plusOne {
                        TextField("Plus One Name (Optional)", text: $plusOneName)
                    }
                }

                Section("Other Details") {
                    TextField("Table Number / Seating", text: $tableNumber)
                    Toggle("VIP Guest", isOn: $isVIP)
                    Toggle("WhatsApp RSVP Opt-In", isOn: $whatsappOptIn)
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }

                if isEditing {
                    Section {
                        Button("Delete Guest", role: .destructive) {
                            if let g = editGuest {
                                store.deleteGuest(g)
                            }
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") {
                        saveGuest()
                    }
                    .fontWeight(.semibold)
                    .disabled(firstName.isEmpty)
                }
            }
        }
        .onAppear {
            if let g = editGuest {
                firstName = g.firstName
                lastName = g.lastName
                phone = g.phone
                email = g.email
                city = g.city
                relationship = g.relationship
                relationshipSide = g.relationshipSide
                dietaryPreference = g.dietaryPreference
                rsvpStatus = g.rsvpStatus
                selectedHouseholdId = g.householdId
                selectedEventIds = Set(g.eventsAttending)
                plusOne = g.plusOne
                plusOneName = g.plusOneName
                tableNumber = g.tableNumber
                isVIP = g.isVIP
                whatsappOptIn = g.whatsappOptIn
                notes = g.notes
            }
        }
    }

    func saveGuest() {
        var guest = editGuest ?? Guest(firstName: firstName, lastName: lastName)
        guest.firstName = firstName
        guest.lastName = lastName
        guest.phone = phone
        guest.email = email
        guest.city = city
        guest.relationship = relationship
        guest.relationshipSide = relationshipSide
        guest.dietaryPreference = dietaryPreference
        guest.rsvpStatus = rsvpStatus
        guest.householdId = selectedHouseholdId
        guest.eventsAttending = Array(selectedEventIds)
        guest.plusOne = plusOne
        guest.plusOneName = plusOneName
        guest.tableNumber = tableNumber
        guest.isVIP = isVIP
        guest.whatsappOptIn = whatsappOptIn
        guest.notes = notes
        if rsvpStatus != .pending { guest.rsvpDate = Date() }

        if isEditing {
            store.updateGuest(guest)
        } else {
            store.addGuest(guest)
        }

        // Update household membership if household selected
        if let hid = selectedHouseholdId {
            if let idx = store.households.firstIndex(where: { $0.id == hid }) {
                if !store.households[idx].memberIds.contains(guest.id) {
                    store.households[idx].memberIds.append(guest.id)
                    store.updateHousehold(store.households[idx])
                }
            }
        }

        dismiss()
    }
}

// MARK: - Add Household View
struct AddHouseholdView: View {
    @EnvironmentObject var store: WeddingStore
    @Environment(\.dismiss) var dismiss

    @State private var familyName = ""
    @State private var headOfFamily = ""
    @State private var phone = ""
    @State private var address = ""
    @State private var city = ""
    @State private var relationshipSide: RelationshipSide = .brideSide
    @State private var relationship = ""
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Household Info") {
                    TextField("Family Name (e.g. Sharma Family)", text: $familyName)
                    TextField("Head of Family", text: $headOfFamily)
                    TextField("Contact Phone", text: $phone)
                        .keyboardType(.phonePad)
                }

                Section("Location") {
                    TextField("Address", text: $address, axis: .vertical)
                        .lineLimit(2...3)
                    TextField("City", text: $city)
                }

                Section("Relationship") {
                    Picker("Side", selection: $relationshipSide) {
                        ForEach(RelationshipSide.allCases, id: \.self) { side in
                            Text(side.rawValue).tag(side)
                        }
                    }
                    TextField("Relationship to couple", text: $relationship)
                }

                Section("Notes") {
                    TextField("Any notes...", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("Add Household")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { saveHousehold() }
                        .fontWeight(.semibold)
                        .disabled(familyName.isEmpty)
                }
            }
        }
    }

    func saveHousehold() {
        var household = Household(familyName: familyName)
        household.headOfFamily = headOfFamily
        household.phone = phone
        household.address = address
        household.city = city
        household.relationshipSide = relationshipSide
        household.relationship = relationship
        household.notes = notes
        store.addHousehold(household)
        dismiss()
    }
}
