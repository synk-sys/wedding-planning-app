import SwiftUI

struct VendorManagementView: View {
    @EnvironmentObject var store: WeddingStore
    @State private var showAddVendor = false
    @State private var searchText = ""
    @State private var selectedCategory: VendorCategory? = nil
    @State private var showBookedOnly = false

    var filteredVendors: [Vendor] {
        var vendors = store.vendors

        if !searchText.isEmpty {
            vendors = vendors.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.category.rawValue.localizedCaseInsensitiveContains(searchText) ||
                $0.contactPerson.localizedCaseInsensitiveContains(searchText)
            }
        }

        if let cat = selectedCategory {
            vendors = vendors.filter { $0.category == cat }
        }

        if showBookedOnly {
            vendors = vendors.filter { $0.isBooked }
        }

        return vendors.sorted { $0.name < $1.name }
    }

    var totalContractValue: Double {
        store.vendors.filter { $0.isBooked }.reduce(0) { $0 + $1.contractAmount }
    }

    var totalBalanceDue: Double {
        store.vendors.filter { $0.isBooked }.reduce(0) { $0 + $1.balanceDue }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Stats header
            VendorStatsHeader(
                totalVendors: store.vendors.count,
                booked: store.vendorsBooked,
                contractValue: totalContractValue,
                balanceDue: totalBalanceDue
            )

            // Search + Filter
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                    TextField("Search vendors...", text: $searchText)
                    if showBookedOnly {
                        Button(action: { showBookedOnly = false }) {
                            Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                        }
                    }
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(10)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(title: "All", isSelected: selectedCategory == nil) {
                            selectedCategory = nil
                        }
                        FilterChip(title: "Booked", isSelected: showBookedOnly) {
                            showBookedOnly.toggle()
                        }
                        ForEach(VendorCategory.allCases, id: \.self) { cat in
                            FilterChip(title: cat.rawValue, isSelected: selectedCategory == cat) {
                                selectedCategory = selectedCategory == cat ? nil : cat
                            }
                        }
                    }
                }
            }
            .padding(12)
            .background(Color(.systemBackground))

            // Vendor List
            if filteredVendors.isEmpty {
                EmptyStateView(icon: "briefcase", title: "No Vendors Found", subtitle: "Tap + to add a vendor")
            } else {
                List {
                    ForEach(filteredVendors) { vendor in
                        NavigationLink {
                            VendorDetailView(vendor: vendor)
                                .environmentObject(store)
                        } label: {
                            VendorListRow(vendor: vendor)
                        }
                    }
                    .onDelete { offsets in
                        offsets.forEach { i in store.deleteVendor(filteredVendors[i]) }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Vendors")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAddVendor = true }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(VivahTheme.deepRed)
                        .font(.title3)
                }
            }
        }
        .sheet(isPresented: $showAddVendor) {
            AddVendorView()
                .environmentObject(store)
        }
    }
}

// MARK: - Stats Header
struct VendorStatsHeader: View {
    let totalVendors: Int
    let booked: Int
    let contractValue: Double
    let balanceDue: Double

    var body: some View {
        HStack(spacing: 0) {
            VendorStatCell(value: "\(totalVendors)", label: "Total")
            Divider().frame(height: 36)
            VendorStatCell(value: "\(booked)", label: "Booked")
            Divider().frame(height: 36)
            VendorStatCell(value: contractValue.inrShortFormatted, label: "Contract")
            Divider().frame(height: 36)
            VendorStatCell(value: balanceDue.inrShortFormatted, label: "Balance Due", color: balanceDue > 0 ? .orange : .green)
        }
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct VendorStatCell: View {
    let value: String
    let label: String
    var color: Color = VivahTheme.deepRed

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Vendor List Row
struct VendorListRow: View {
    let vendor: Vendor

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(vendor.isBooked ? VivahTheme.gold.opacity(0.15) : Color(.systemGray5))
                    .frame(width: 44, height: 44)
                Image(systemName: vendor.category.icon)
                    .foregroundColor(vendor.isBooked ? VivahTheme.gold : .secondary)
                    .font(.system(size: 16))
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(vendor.name)
                        .font(.subheadline).fontWeight(.semibold)
                    if vendor.isContractSigned {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                }
                Text(vendor.category.rawValue)
                    .font(.caption).foregroundColor(.secondary)
                if !vendor.contactPerson.isEmpty {
                    Text(vendor.contactPerson)
                        .font(.caption2).foregroundColor(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if vendor.contractAmount > 0 {
                    Text(vendor.contractAmount.inrShortFormatted)
                        .font(.subheadline).fontWeight(.semibold)
                }
                if vendor.isBooked {
                    Text(vendor.balanceDue > 0 ? "Due: \(vendor.balanceDue.inrShortFormatted)" : "Paid")
                        .font(.caption2)
                        .foregroundColor(vendor.balanceDue > 0 ? .orange : .green)
                } else {
                    Text("Not Booked")
                        .font(.caption2).foregroundColor(.secondary)
                }

                // Star rating
                if vendor.rating > 0 {
                    HStack(spacing: 1) {
                        ForEach(1...5, id: \.self) { i in
                            Image(systemName: i <= vendor.rating ? "star.fill" : "star")
                                .font(.system(size: 7))
                                .foregroundColor(VivahTheme.gold)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add Vendor View
struct AddVendorView: View {
    @EnvironmentObject var store: WeddingStore
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var category: VendorCategory = .photographer
    @State private var contactPerson = ""
    @State private var phone = ""
    @State private var email = ""
    @State private var website = ""
    @State private var address = ""
    @State private var contractAmount = ""
    @State private var advancePaid = ""
    @State private var isBooked = false
    @State private var isContractSigned = false
    @State private var rating = 0
    @State private var notes = ""
    @State private var contractNotes = ""
    @State private var instagramHandle = ""
    @State private var referredBy = ""
    @State private var selectedEventIds: Set<UUID> = []

    var body: some View {
        NavigationStack {
            Form {
                Section("Vendor Info") {
                    TextField("Vendor / Studio Name", text: $name)
                    Picker("Category", selection: $category) {
                        ForEach(VendorCategory.allCases, id: \.self) { cat in
                            Label(cat.rawValue, systemImage: cat.icon).tag(cat)
                        }
                    }
                    TextField("Contact Person", text: $contactPerson)
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                    TextField("Website", text: $website)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                    TextField("Instagram (@handle)", text: $instagramHandle)
                        .textInputAutocapitalization(.never)
                }

                Section("Contract") {
                    Toggle("Booked", isOn: $isBooked)
                    Toggle("Contract Signed", isOn: $isContractSigned)
                    HStack {
                        Text("Contract Amount (₹)")
                        Spacer()
                        TextField("0", text: $contractAmount)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Advance Paid (₹)")
                        Spacer()
                        TextField("0", text: $advancePaid)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    TextField("Contract Notes", text: $contractNotes, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section("Events") {
                    ForEach(store.events) { event in
                        HStack {
                            Text(event.name)
                            Spacer()
                            Image(systemName: selectedEventIds.contains(event.id) ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(selectedEventIds.contains(event.id) ? VivahTheme.deepRed : .secondary)
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
                }

                Section("Rating & Notes") {
                    HStack(spacing: 8) {
                        Text("Rating")
                        Spacer()
                        HStack(spacing: 4) {
                            ForEach(1...5, id: \.self) { i in
                                Image(systemName: i <= rating ? "star.fill" : "star")
                                    .foregroundColor(VivahTheme.gold)
                                    .font(.title3)
                                    .onTapGesture { rating = i }
                            }
                        }
                    }
                    TextField("Referred By", text: $referredBy)
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("Add Vendor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { saveVendor() }
                        .disabled(name.isEmpty)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    func saveVendor() {
        var vendor = Vendor(name: name, category: category)
        vendor.contactPerson = contactPerson
        vendor.phone = phone
        vendor.email = email
        vendor.website = website
        vendor.address = address
        vendor.contractAmount = Double(contractAmount) ?? 0
        vendor.advancePaid = Double(advancePaid) ?? 0
        vendor.isBooked = isBooked
        vendor.isContractSigned = isContractSigned
        vendor.rating = rating
        vendor.notes = notes
        vendor.contractNotes = contractNotes
        vendor.instagramHandle = instagramHandle
        vendor.referredBy = referredBy
        vendor.assignedEvents = Array(selectedEventIds)

        // Auto add advance as a paid milestone
        if vendor.advancePaid > 0 {
            let milestone = PaymentMilestone(
                description: "Advance Payment",
                amount: vendor.advancePaid,
                dueDate: Date(),
                isPaid: true,
                paidDate: Date()
            )
            vendor.paymentMilestones.append(milestone)
        }

        store.addVendor(vendor)
        dismiss()
    }
}
