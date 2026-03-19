import SwiftUI

struct VendorDetailView: View {
    @EnvironmentObject var store: WeddingStore
    @Environment(\.dismiss) var dismiss
    @State var vendor: Vendor
    @State private var showEdit = false
    @State private var showAddMilestone = false
    @State private var selectedTab = 0

    init(vendor: Vendor) {
        _vendor = State(initialValue: vendor)
    }

    var assignedEvents: [WeddingEvent] {
        store.events.filter { vendor.assignedEvents.contains($0.id) }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Hero Header
                ZStack(alignment: .bottomLeading) {
                    Rectangle()
                        .fill(vendor.isBooked ? VivahTheme.gradient : LinearGradient(colors: [Color(.systemGray3), Color(.systemGray4)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(height: 160)

                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 8) {
                                Image(systemName: vendor.category.icon)
                                    .font(.caption)
                                    .foregroundColor(VivahTheme.gold)
                                Text(vendor.category.rawValue)
                                    .font(.caption)
                                    .foregroundColor(VivahTheme.gold.opacity(0.9))
                            }
                            Text(vendor.name)
                                .font(.system(size: 26, weight: .bold, design: .serif))
                                .foregroundColor(VivahTheme.ivory)
                            if !vendor.contactPerson.isEmpty {
                                Text(vendor.contactPerson)
                                    .font(.subheadline)
                                    .foregroundColor(VivahTheme.ivory.opacity(0.8))
                            }
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            if vendor.isBooked {
                                Label("Booked", systemImage: "checkmark.circle.fill")
                                    .font(.caption).fontWeight(.semibold)
                                    .padding(.horizontal, 10).padding(.vertical, 4)
                                    .background(Color.green.opacity(0.2))
                                    .foregroundColor(.green)
                                    .cornerRadius(10)
                            }
                            if vendor.isContractSigned {
                                Label("Contract Signed", systemImage: "signature")
                                    .font(.caption2)
                                    .foregroundColor(VivahTheme.gold.opacity(0.8))
                            }
                            // Star rating
                            if vendor.rating > 0 {
                                HStack(spacing: 2) {
                                    ForEach(1...5, id: \.self) { i in
                                        Image(systemName: i <= vendor.rating ? "star.fill" : "star")
                                            .font(.caption)
                                            .foregroundColor(VivahTheme.gold)
                                    }
                                }
                            }
                        }
                    }
                    .padding(20)
                }

                // Payment Summary Strip
                HStack(spacing: 0) {
                    VendorPaymentCell(label: "Contract", value: vendor.contractAmount.inrShortFormatted, color: VivahTheme.deepRed)
                    Divider().frame(height: 40)
                    VendorPaymentCell(label: "Paid", value: vendor.totalPaid.inrShortFormatted, color: .green)
                    Divider().frame(height: 40)
                    VendorPaymentCell(label: "Balance", value: vendor.balanceDue.inrShortFormatted, color: vendor.balanceDue > 0 ? .orange : .green)
                    Divider().frame(height: 40)
                    VStack(spacing: 2) {
                        Text("\(vendor.paymentMilestones.filter { $0.isPaid }.count)/\(vendor.paymentMilestones.count)")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                        Text("Milestones")
                            .font(.caption2).foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)

                // Tab Picker
                Picker("", selection: $selectedTab) {
                    Text("Overview").tag(0)
                    Text("Payments").tag(1)
                    Text("Events").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(16)
                .background(Color(.systemBackground))

                // Tab content
                VStack(spacing: 16) {
                    switch selectedTab {
                    case 0: VendorOverviewTab(vendor: vendor)
                    case 1: VendorPaymentsTab(vendor: $vendor, showAddMilestone: $showAddMilestone)
                        .environmentObject(store)
                    case 2: VendorEventsTab(assignedEvents: assignedEvents)
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
            EditVendorView(vendor: vendor) { updated in
                store.updateVendor(updated)
                vendor = updated
            }
        }
        .sheet(isPresented: $showAddMilestone) {
            AddMilestoneView { milestone in
                vendor.paymentMilestones.append(milestone)
                store.updateVendor(vendor)
            }
        }
        .onReceive(store.$vendors) { vendors in
            if let updated = vendors.first(where: { $0.id == vendor.id }) {
                vendor = updated
            }
        }
    }
}

struct VendorPaymentCell: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(color)
            Text(label)
                .font(.caption2).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Overview Tab
struct VendorOverviewTab: View {
    let vendor: Vendor

    var body: some View {
        VStack(spacing: 14) {
            // Contact info
            InfoCard(title: "Contact Information") {
                VStack(spacing: 8) {
                    if !vendor.phone.isEmpty {
                        ContactRow(icon: "phone.fill", value: vendor.phone, action: {
                            if let url = URL(string: "tel://\(vendor.phone)") {
                                UIApplication.shared.open(url)
                            }
                        })
                    }
                    if !vendor.email.isEmpty {
                        ContactRow(icon: "envelope.fill", value: vendor.email, action: {
                            if let url = URL(string: "mailto:\(vendor.email)") {
                                UIApplication.shared.open(url)
                            }
                        })
                    }
                    if !vendor.website.isEmpty {
                        ContactRow(icon: "globe", value: vendor.website, action: {
                            if let url = URL(string: vendor.website) {
                                UIApplication.shared.open(url)
                            }
                        })
                    }
                    if !vendor.instagramHandle.isEmpty {
                        ContactRow(icon: "camera.fill", value: "@\(vendor.instagramHandle)", action: {
                            let handle = vendor.instagramHandle.replacingOccurrences(of: "@", with: "")
                            if let url = URL(string: "https://instagram.com/\(handle)") {
                                UIApplication.shared.open(url)
                            }
                        })
                    }
                    if !vendor.address.isEmpty {
                        HStack(spacing: 10) {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(VivahTheme.gold)
                            Text(vendor.address)
                                .font(.subheadline)
                        }
                    }
                }
            }

            if !vendor.contractNotes.isEmpty {
                InfoCard(title: "Contract Notes") {
                    Text(vendor.contractNotes)
                        .font(.subheadline).foregroundColor(.secondary)
                }
            }

            if !vendor.referredBy.isEmpty {
                InfoCard(title: "Referral") {
                    Label(vendor.referredBy, systemImage: "person.fill.checkmark")
                        .font(.subheadline)
                }
            }

            if !vendor.notes.isEmpty {
                InfoCard(title: "Notes") {
                    Text(vendor.notes)
                        .font(.subheadline).foregroundColor(.secondary)
                }
            }
        }
    }
}

struct ContactRow: View {
    let icon: String
    let value: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .foregroundColor(VivahTheme.gold)
                    .frame(width: 20)
                Text(value)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Payments Tab
struct VendorPaymentsTab: View {
    @EnvironmentObject var store: WeddingStore
    @Binding var vendor: Vendor
    @Binding var showAddMilestone: Bool

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Payment Milestones")
                    .font(.headline)
                Spacer()
                Button(action: { showAddMilestone = true }) {
                    Label("Add", systemImage: "plus")
                        .font(.caption).fontWeight(.semibold)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(VivahTheme.deepRed)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                }
            }

            if vendor.paymentMilestones.isEmpty {
                Text("No payment milestones added.")
                    .font(.subheadline).foregroundColor(.secondary)
                    .padding(.vertical, 20)
            } else {
                ForEach(vendor.paymentMilestones.indices, id: \.self) { i in
                    MilestoneRow(milestone: $vendor.paymentMilestones[i]) { milestone in
                        vendor.paymentMilestones[i] = milestone
                        store.updateVendor(vendor)
                    }
                }
            }

            // Balance summary
            VStack(spacing: 8) {
                HStack {
                    Text("Contract Total")
                    Spacer()
                    Text(vendor.contractAmount.inrFormatted).fontWeight(.semibold)
                }
                HStack {
                    Text("Total Paid")
                    Spacer()
                    Text(vendor.totalPaid.inrFormatted).fontWeight(.semibold).foregroundColor(.green)
                }
                Divider()
                HStack {
                    Text("Balance Due")
                        .fontWeight(.semibold)
                    Spacer()
                    Text(vendor.balanceDue.inrFormatted)
                        .fontWeight(.bold)
                        .foregroundColor(vendor.balanceDue > 0 ? .orange : .green)
                }
            }
            .padding(14)
            .background(Color(.systemBackground))
            .cornerRadius(14)
        }
    }
}

struct MilestoneRow: View {
    @Binding var milestone: PaymentMilestone
    let onToggle: (PaymentMilestone) -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: {
                milestone.isPaid.toggle()
                if milestone.isPaid { milestone.paidDate = Date() }
                else { milestone.paidDate = nil }
                onToggle(milestone)
            }) {
                Image(systemName: milestone.isPaid ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(milestone.isPaid ? .green : .secondary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(milestone.description)
                    .font(.subheadline).fontWeight(.medium)
                    .strikethrough(milestone.isPaid)
                HStack(spacing: 6) {
                    Text("Due: \(milestone.dueDate, style: .date)")
                        .font(.caption).foregroundColor(.secondary)
                    if milestone.isPaid, let pd = milestone.paidDate {
                        Text("Paid: \(pd, style: .date)")
                            .font(.caption).foregroundColor(.green)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(milestone.amount.inrShortFormatted)
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundColor(milestone.isPaid ? .green : .orange)
                Text(milestone.paidBy.rawValue)
                    .font(.caption2).foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Events Tab
struct VendorEventsTab: View {
    let assignedEvents: [WeddingEvent]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Assigned Events")
                .font(.headline)

            if assignedEvents.isEmpty {
                Text("Not assigned to any events yet.")
                    .font(.subheadline).foregroundColor(.secondary)
                    .padding(.vertical, 20)
            } else {
                ForEach(assignedEvents) { event in
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(VivahTheme.gold.opacity(0.15))
                                .frame(width: 36, height: 36)
                            Image(systemName: "calendar")
                                .font(.caption)
                                .foregroundColor(VivahTheme.gold)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(event.name)
                                .font(.subheadline).fontWeight(.medium)
                            Text(event.date, style: .date)
                                .font(.caption).foregroundColor(.secondary)
                            if !event.venue.isEmpty {
                                Text(event.venue)
                                    .font(.caption2).foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        let days = Calendar.current.dateComponents([.day], from: Date(), to: event.date).day ?? 0
                        if days >= 0 {
                            Text("\(days)d")
                                .font(.caption2).fontWeight(.semibold)
                                .foregroundColor(VivahTheme.deepRed)
                        }
                    }
                    .padding(12)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                }
            }
        }
    }
}

// MARK: - Add Milestone View
struct AddMilestoneView: View {
    @Environment(\.dismiss) var dismiss
    @State private var description = ""
    @State private var amount = ""
    @State private var dueDate = Date()
    @State private var isPaid = false
    @State private var paidBy: FamilySide = .shared
    let onSave: (PaymentMilestone) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Milestone Details") {
                    TextField("Description (e.g. 50% advance, Final payment)", text: $description)
                    HStack {
                        Text("Amount (₹)")
                        Spacer()
                        TextField("0", text: $amount)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                }
                Section("Payment") {
                    Toggle("Already Paid", isOn: $isPaid)
                    Picker("Paid By", selection: $paidBy) {
                        ForEach(FamilySide.allCases, id: \.self) { side in
                            Text(side.rawValue).tag(side)
                        }
                    }
                }
            }
            .navigationTitle("Add Milestone")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        var milestone = PaymentMilestone(
                            description: description,
                            amount: Double(amount) ?? 0,
                            dueDate: dueDate
                        )
                        milestone.isPaid = isPaid
                        if isPaid { milestone.paidDate = Date() }
                        milestone.paidBy = paidBy
                        onSave(milestone)
                        dismiss()
                    }
                    .disabled(description.isEmpty || amount.isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Edit Vendor View
struct EditVendorView: View {
    @Environment(\.dismiss) var dismiss
    @State private var vendor: Vendor
    let onSave: (Vendor) -> Void

    init(vendor: Vendor, onSave: @escaping (Vendor) -> Void) {
        _vendor = State(initialValue: vendor)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Vendor Info") {
                    TextField("Name", text: $vendor.name)
                    Picker("Category", selection: $vendor.category) {
                        ForEach(VendorCategory.allCases, id: \.self) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }
                    TextField("Contact Person", text: $vendor.contactPerson)
                    TextField("Phone", text: $vendor.phone)
                    TextField("Email", text: $vendor.email)
                    TextField("Website", text: $vendor.website)
                    TextField("Instagram", text: $vendor.instagramHandle)
                }
                Section("Contract") {
                    Toggle("Booked", isOn: $vendor.isBooked)
                    Toggle("Contract Signed", isOn: $vendor.isContractSigned)
                    HStack {
                        Text("Contract Amount")
                        Spacer()
                        TextField("0", value: $vendor.contractAmount, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                Section("Rating") {
                    HStack {
                        Text("Rating")
                        Spacer()
                        HStack(spacing: 6) {
                            ForEach(1...5, id: \.self) { i in
                                Image(systemName: i <= vendor.rating ? "star.fill" : "star")
                                    .foregroundColor(VivahTheme.gold)
                                    .onTapGesture { vendor.rating = i }
                            }
                        }
                    }
                }
                Section("Notes") {
                    TextField("Contract Notes", text: $vendor.contractNotes, axis: .vertical).lineLimit(2...4)
                    TextField("General Notes", text: $vendor.notes, axis: .vertical).lineLimit(2...4)
                }
            }
            .navigationTitle("Edit Vendor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { onSave(vendor); dismiss() }.fontWeight(.semibold)
                }
            }
        }
    }
}
