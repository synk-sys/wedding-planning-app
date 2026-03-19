import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var store: WeddingStore
    @State private var currentPage = 0
    @State private var brideName = ""
    @State private var groomName = ""
    @State private var weddingDate = Date().addingTimeInterval(60 * 60 * 24 * 180)
    @State private var venue = ""
    @State private var city = ""
    @State private var selectedReligion: Religion = .northIndianHindu
    @State private var totalBudget: Double = 2000000
    @State private var brideFamilyShare: Double = 50
    @State private var budgetText = "20,00,000"
    @State private var animateIn = false

    let pageCount = 4

    var body: some View {
        ZStack {
            VivahTheme.gradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("विवाह")
                            .font(.system(size: 36, weight: .bold, design: .serif))
                            .foregroundColor(VivahTheme.gold)
                        Text("VIVAH")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(VivahTheme.ivory.opacity(0.8))
                            .kerning(4)
                    }
                    Spacer()
                    Text("Step \(currentPage + 1) of \(pageCount)")
                        .font(.caption)
                        .foregroundColor(VivahTheme.ivory.opacity(0.7))
                }
                .padding(.horizontal, 28)
                .padding(.top, 20)

                // Progress Bar
                HStack(spacing: 6) {
                    ForEach(0..<pageCount, id: \.self) { i in
                        Capsule()
                            .fill(i <= currentPage ? VivahTheme.gold : VivahTheme.ivory.opacity(0.3))
                            .frame(height: 4)
                            .animation(.spring(), value: currentPage)
                    }
                }
                .padding(.horizontal, 28)
                .padding(.top, 16)
                .padding(.bottom, 24)

                // Page Content
                TabView(selection: $currentPage) {
                    WelcomePage(animateIn: $animateIn)
                        .tag(0)
                    CoupleDetailsPage(brideName: $brideName, groomName: $groomName, weddingDate: $weddingDate, venue: $venue, city: $city)
                        .tag(1)
                    ReligionSelectionPage(selectedReligion: $selectedReligion)
                        .tag(2)
                    BudgetSetupPage(totalBudget: $totalBudget, budgetText: $budgetText, brideFamilyShare: $brideFamilyShare)
                        .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)

                // Navigation Buttons
                HStack(spacing: 16) {
                    if currentPage > 0 {
                        Button(action: { withAnimation { currentPage -= 1 } }) {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .foregroundColor(VivahTheme.ivory)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 14)
                            .background(VivahTheme.ivory.opacity(0.2))
                            .cornerRadius(14)
                        }
                    }

                    Button(action: handleNext) {
                        HStack {
                            Text(currentPage == pageCount - 1 ? "Begin Planning" : "Continue")
                                .fontWeight(.semibold)
                            Image(systemName: currentPage == pageCount - 1 ? "sparkles" : "chevron.right")
                        }
                        .foregroundColor(VivahTheme.maroon)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(VivahTheme.gold)
                        .cornerRadius(14)
                    }
                    .disabled(!canProceed)
                    .opacity(canProceed ? 1 : 0.6)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 40)
            }
        }
        .onAppear { withAnimation(.easeIn(duration: 0.6)) { animateIn = true } }
    }

    var canProceed: Bool {
        switch currentPage {
        case 1: return !brideName.isEmpty && !groomName.isEmpty
        default: return true
        }
    }

    func handleNext() {
        if currentPage < pageCount - 1 {
            withAnimation { currentPage += 1 }
        } else {
            finishOnboarding()
        }
    }

    func finishOnboarding() {
        var wedding = Wedding()
        wedding.brideName = brideName
        wedding.groomName = groomName
        wedding.weddingDate = weddingDate
        wedding.venue = venue
        wedding.city = city
        wedding.religion = selectedReligion
        wedding.totalBudget = totalBudget
        wedding.brideFamilyBudgetShare = brideFamilyShare

        let events = store.generateDefaultEvents(for: selectedReligion, weddingDate: weddingDate)
        store.wedding = wedding
        let checklist = store.generateDefaultChecklist(for: selectedReligion)
        store.completeOnboarding(wedding: wedding, events: events, checklist: checklist)
    }
}

// MARK: - Welcome Page
struct WelcomePage: View {
    @Binding var animateIn: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                // Mandala-inspired decoration
                ZStack {
                    Circle()
                        .stroke(VivahTheme.gold.opacity(0.3), lineWidth: 1)
                        .frame(width: 180, height: 180)
                    Circle()
                        .stroke(VivahTheme.gold.opacity(0.5), lineWidth: 1)
                        .frame(width: 140, height: 140)
                    Circle()
                        .fill(VivahTheme.gold.opacity(0.15))
                        .frame(width: 100, height: 100)
                    Text("🪷")
                        .font(.system(size: 50))
                }
                .scaleEffect(animateIn ? 1 : 0.5)
                .opacity(animateIn ? 1 : 0)
                .animation(.spring(response: 0.8, dampingFraction: 0.6), value: animateIn)

                VStack(spacing: 12) {
                    Text("Your Perfect Wedding\nStarts Here")
                        .font(.system(size: 28, weight: .bold, design: .serif))
                        .foregroundColor(VivahTheme.ivory)
                        .multilineTextAlignment(.center)
                        .opacity(animateIn ? 1 : 0)
                        .animation(.easeIn(duration: 0.6).delay(0.3), value: animateIn)

                    Text("Plan every ceremony, every guest, every detail of your Indian wedding — all in one beautiful app.")
                        .font(.subheadline)
                        .foregroundColor(VivahTheme.ivory.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .opacity(animateIn ? 1 : 0)
                        .animation(.easeIn(duration: 0.6).delay(0.5), value: animateIn)
                }

                VStack(spacing: 14) {
                    FeatureRow(icon: "calendar.badge.clock", text: "Multi-event planning for every ceremony")
                    FeatureRow(icon: "person.3.fill", text: "Joint family collaboration tools")
                    FeatureRow(icon: "indianrupeesign.circle", text: "Per-ceremony budget with family split")
                    FeatureRow(icon: "message.fill", text: "WhatsApp RSVP — no app needed for guests")
                    FeatureRow(icon: "gift.fill", text: "Shagun & gift tracking")
                }
                .opacity(animateIn ? 1 : 0)
                .animation(.easeIn(duration: 0.6).delay(0.7), value: animateIn)

                Spacer(minLength: 20)
            }
            .padding(.horizontal, 28)
            .padding(.top, 10)
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(VivahTheme.gold)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
                .foregroundColor(VivahTheme.ivory.opacity(0.9))
            Spacer()
        }
    }
}

// MARK: - Couple Details Page
struct CoupleDetailsPage: View {
    @Binding var brideName: String
    @Binding var groomName: String
    @Binding var weddingDate: Date
    @Binding var venue: String
    @Binding var city: String

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 6) {
                    Text("Tell Us About Your Wedding")
                        .font(.system(size: 24, weight: .bold, design: .serif))
                        .foregroundColor(VivahTheme.ivory)
                    Text("We'll personalize everything for you")
                        .font(.subheadline)
                        .foregroundColor(VivahTheme.ivory.opacity(0.7))
                }

                VStack(spacing: 16) {
                    OnboardingTextField(
                        title: "Bride's Name",
                        placeholder: "Enter bride's name",
                        text: $brideName,
                        icon: "person.fill"
                    )

                    OnboardingTextField(
                        title: "Groom's Name",
                        placeholder: "Enter groom's name",
                        text: $groomName,
                        icon: "person.fill"
                    )

                    VStack(alignment: .leading, spacing: 8) {
                        Label("Wedding Date", systemImage: "calendar")
                            .font(.caption)
                            .foregroundColor(VivahTheme.gold)
                            .textCase(.uppercase)
                            .kerning(0.5)

                        DatePicker("", selection: $weddingDate, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .colorScheme(.dark)
                            .padding(14)
                            .background(VivahTheme.ivory.opacity(0.1))
                            .cornerRadius(12)
                    }

                    OnboardingTextField(
                        title: "Wedding Venue (Optional)",
                        placeholder: "Hotel / Banquet / Farm House",
                        text: $venue,
                        icon: "building.2.fill"
                    )

                    OnboardingTextField(
                        title: "City",
                        placeholder: "Delhi, Mumbai, Chennai...",
                        text: $city,
                        icon: "location.fill"
                    )
                }

                Spacer(minLength: 20)
            }
            .padding(.horizontal, 28)
            .padding(.top, 10)
        }
    }
}

struct OnboardingTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.caption)
                .foregroundColor(VivahTheme.gold)
                .textCase(.uppercase)
                .kerning(0.5)

            TextField(placeholder, text: $text)
                .foregroundColor(VivahTheme.ivory)
                .padding(14)
                .background(VivahTheme.ivory.opacity(0.1))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(text.isEmpty ? Color.clear : VivahTheme.gold.opacity(0.5), lineWidth: 1)
                )
        }
    }
}

// MARK: - Religion Selection Page
struct ReligionSelectionPage: View {
    @Binding var selectedReligion: Religion

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 6) {
                    Text("Wedding Tradition")
                        .font(.system(size: 24, weight: .bold, design: .serif))
                        .foregroundColor(VivahTheme.ivory)
                    Text("We'll set up the right ceremonies & checklist")
                        .font(.subheadline)
                        .foregroundColor(VivahTheme.ivory.opacity(0.7))
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 10) {
                    ForEach(Religion.allCases, id: \.self) { religion in
                        ReligionCard(
                            religion: religion,
                            isSelected: selectedReligion == religion,
                            action: { selectedReligion = religion }
                        )
                    }
                }

                if !selectedReligion.defaultEvents.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Ceremonies to be planned:")
                            .font(.caption)
                            .foregroundColor(VivahTheme.gold)
                            .textCase(.uppercase)
                            .kerning(0.5)
                        FlowLayout(items: selectedReligion.defaultEvents) { event in
                            Text(event)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(VivahTheme.gold.opacity(0.2))
                                .foregroundColor(VivahTheme.ivory)
                                .cornerRadius(20)
                        }
                    }
                    .padding(16)
                    .background(VivahTheme.ivory.opacity(0.08))
                    .cornerRadius(14)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .animation(.easeInOut(duration: 0.3), value: selectedReligion)
                }

                Spacer(minLength: 20)
            }
            .padding(.horizontal, 28)
            .padding(.top, 10)
        }
    }
}

struct ReligionCard: View {
    let religion: Religion
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Text(religionEmoji)
                    .font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text(religion.rawValue)
                        .font(.subheadline).fontWeight(.semibold)
                        .foregroundColor(isSelected ? VivahTheme.maroon : VivahTheme.ivory)
                    Text("\(religion.defaultEvents.count) ceremonies")
                        .font(.caption)
                        .foregroundColor(isSelected ? VivahTheme.maroon.opacity(0.7) : VivahTheme.ivory.opacity(0.6))
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(VivahTheme.maroon)
                }
            }
            .padding(14)
            .background(isSelected ? VivahTheme.gold : VivahTheme.ivory.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? VivahTheme.gold : Color.clear, lineWidth: 1.5)
            )
        }
        .animation(.spring(response: 0.3), value: isSelected)
    }

    var religionEmoji: String {
        switch religion {
        case .northIndianHindu: return "🪔"
        case .southIndianHindu: return "🌺"
        case .punjabiSikh: return "🟠"
        case .muslimNikah: return "🌙"
        case .bengaliHindu: return "🌸"
        case .gujaratiMarwari: return "🎪"
        case .christian: return "⛪"
        }
    }
}

// MARK: - Budget Setup Page
struct BudgetSetupPage: View {
    @Binding var totalBudget: Double
    @Binding var budgetText: String
    @Binding var brideFamilyShare: Double

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 6) {
                    Text("Budget Planning")
                        .font(.system(size: 24, weight: .bold, design: .serif))
                        .foregroundColor(VivahTheme.ivory)
                    Text("Set your total wedding budget")
                        .font(.subheadline)
                        .foregroundColor(VivahTheme.ivory.opacity(0.7))
                }

                VStack(alignment: .leading, spacing: 12) {
                    Label("Total Wedding Budget (₹)", systemImage: "indianrupeesign.circle")
                        .font(.caption)
                        .foregroundColor(VivahTheme.gold)
                        .textCase(.uppercase)
                        .kerning(0.5)

                    TextField("Enter amount", text: $budgetText)
                        .keyboardType(.numberPad)
                        .foregroundColor(VivahTheme.ivory)
                        .font(.title2).fontWeight(.semibold)
                        .padding(14)
                        .background(VivahTheme.ivory.opacity(0.1))
                        .cornerRadius(12)
                        .onChange(of: budgetText) { newVal in
                            let digits = newVal.filter { $0.isNumber }
                            if let val = Double(digits) {
                                totalBudget = val
                            }
                        }

                    // Quick select buttons
                    HStack(spacing: 8) {
                        ForEach(["10L", "25L", "50L", "1Cr", "2Cr"], id: \.self) { label in
                            Button(action: {
                                let amounts: [String: Double] = ["10L": 1000000, "25L": 2500000, "50L": 5000000, "1Cr": 10000000, "2Cr": 20000000]
                                if let amount = amounts[label] {
                                    totalBudget = amount
                                    budgetText = String(Int(amount))
                                }
                            }) {
                                Text(label)
                                    .font(.caption).fontWeight(.medium)
                                    .padding(.horizontal, 12).padding(.vertical, 7)
                                    .background(VivahTheme.ivory.opacity(0.15))
                                    .foregroundColor(VivahTheme.ivory)
                                    .cornerRadius(20)
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Label("Family Budget Split", systemImage: "person.2.fill")
                        .font(.caption)
                        .foregroundColor(VivahTheme.gold)
                        .textCase(.uppercase)
                        .kerning(0.5)

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Bride's Family")
                                .font(.caption).foregroundColor(VivahTheme.ivory.opacity(0.7))
                            Text("\(Int(brideFamilyShare))%")
                                .font(.title3).fontWeight(.bold).foregroundColor(VivahTheme.gold)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Groom's Family")
                                .font(.caption).foregroundColor(VivahTheme.ivory.opacity(0.7))
                            Text("\(Int(100 - brideFamilyShare))%")
                                .font(.title3).fontWeight(.bold).foregroundColor(VivahTheme.roseGold)
                        }
                    }

                    Slider(value: $brideFamilyShare, in: 0...100, step: 5)
                        .tint(VivahTheme.gold)

                    GeometryReader { geo in
                        HStack(spacing: 0) {
                            Rectangle()
                                .fill(VivahTheme.gold)
                                .frame(width: geo.size.width * brideFamilyShare / 100)
                            Rectangle()
                                .fill(VivahTheme.roseGold)
                        }
                        .frame(height: 8)
                        .cornerRadius(4)
                    }
                    .frame(height: 8)

                    HStack {
                        Text("Bride: \(totalBudget * brideFamilyShare / 100).inrShortFormatted")
                            .font(.caption).foregroundColor(VivahTheme.gold)
                        Spacer()
                        Text("Groom: \((totalBudget * (100 - brideFamilyShare) / 100)).inrShortFormatted")
                            .font(.caption).foregroundColor(VivahTheme.roseGold)
                    }
                    .overlay(
                        HStack {
                            Text(budgetSplitBride)
                                .font(.caption).foregroundColor(VivahTheme.gold)
                            Spacer()
                            Text(budgetSplitGroom)
                                .font(.caption).foregroundColor(VivahTheme.roseGold)
                        }
                    )
                }
                .padding(16)
                .background(VivahTheme.ivory.opacity(0.08))
                .cornerRadius(14)

                VStack(alignment: .leading, spacing: 6) {
                    Text("💡 You can adjust this anytime and track per-ceremony expenses separately.")
                        .font(.caption)
                        .foregroundColor(VivahTheme.ivory.opacity(0.6))
                }

                Spacer(minLength: 20)
            }
            .padding(.horizontal, 28)
            .padding(.top, 10)
        }
    }

    var budgetSplitBride: String {
        (totalBudget * brideFamilyShare / 100).inrShortFormatted
    }

    var budgetSplitGroom: String {
        (totalBudget * (100 - brideFamilyShare) / 100).inrShortFormatted
    }
}

// MARK: - Flow Layout
struct FlowLayout<Data: Collection, Content: View>: View where Data.Element: Hashable {
    let items: Data
    let content: (Data.Element) -> Content

    @State private var totalHeight = CGFloat.zero

    var body: some View {
        GeometryReader { geo in
            self.generateContent(in: geo)
        }
        .frame(height: totalHeight)
    }

    private func generateContent(in geo: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero

        return ZStack(alignment: .topLeading) {
            ForEach(Array(items.enumerated()), id: \.element) { _, item in
                content(item)
                    .padding(.all, 4)
                    .alignmentGuide(.leading) { d in
                        if abs(width - d.width) > geo.size.width {
                            width = 0
                            height -= d.height
                        }
                        let result = width
                        if item == items.last! { width = 0 } else { width -= d.width }
                        return result
                    }
                    .alignmentGuide(.top) { _ in
                        let result = height
                        if item == items.last! { height = 0 }
                        return result
                    }
            }
        }
        .background(viewHeightReader($totalHeight))
    }

    private func viewHeightReader(_ binding: Binding<CGFloat>) -> some View {
        GeometryReader { geo -> Color in
            DispatchQueue.main.async {
                binding.wrappedValue = geo.size.height
            }
            return .clear
        }
    }
}
