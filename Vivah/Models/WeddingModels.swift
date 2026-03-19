import Foundation
import SwiftUI

// MARK: - Enums

enum Religion: String, Codable, CaseIterable {
    case northIndianHindu = "North Indian Hindu"
    case southIndianHindu = "South Indian Hindu"
    case punjabiSikh = "Punjabi Sikh"
    case muslimNikah = "Muslim Nikah"
    case bengaliHindu = "Bengali Hindu"
    case gujaratiMarwari = "Gujarati/Marwari Hindu"
    case christian = "Christian"

    var defaultEvents: [String] {
        switch self {
        case .northIndianHindu:
            return ["Roka", "Sagai/Engagement", "Haldi", "Mehndi", "Sangeet", "Pheras (Wedding)", "Reception"]
        case .southIndianHindu:
            return ["Nischayathartham (Engagement)", "Haldi/Nalungu", "Mehndi", "Muhurtham (Wedding)", "Reception"]
        case .punjabiSikh:
            return ["Roka", "Kurmai (Engagement)", "Haldi", "Mehndi", "Sangeet", "Anand Karaj", "Reception"]
        case .muslimNikah:
            return ["Mangni (Engagement)", "Mehndi", "Mayun", "Baraat", "Nikah", "Walima (Reception)"]
        case .bengaliHindu:
            return ["Ashirbaad (Engagement)", "Gaye Holud", "Mehndi", "Biye (Wedding)", "Bou Bhaat (Reception)"]
        case .gujaratiMarwari:
            return ["Sagai (Engagement)", "Ganesh Puja", "Haldi", "Mehndi", "Garba/Sangeet", "Wedding", "Reception"]
        case .christian:
            return ["Engagement", "Bridal Shower", "Bachelor/Bachelorette", "Rehearsal Dinner", "Wedding Ceremony", "Reception"]
        }
    }

    var defaultChecklist: [String] {
        switch self {
        case .northIndianHindu:
            return ["Book pandit/priest", "Book baraat band/dhol", "Arrange ghori (horse)", "Book mandap decorator", "Arrange sindoor & mangalsutra", "Book mehndi artist", "Arrange haldi ingredients", "Book sangeet choreographer", "Prepare jai mala flowers", "Arrange saat pheras rituals"]
        case .southIndianHindu:
            return ["Book vedic priest", "Arrange kashi yatra props", "Book nadaswaram musicians", "Arrange silk sarees for bride", "Book mehndi/nalungu artist", "Arrange thali/mangalsutra", "Book muhurtham venue", "Arrange kanyadanam items", "Book caterer for traditional meals", "Arrange akshata/turmeric"]
        case .punjabiSikh:
            return ["Book gurdwara", "Arrange anand karaj arrangements", "Book kirtan singers", "Arrange sehra for groom", "Book bhangra/giddha performers", "Arrange pink chunni for bride", "Book langar arrangements", "Prepare ardas", "Book doli arrangements", "Arrange milni ceremony gifts"]
        case .muslimNikah:
            return ["Book maulvi/qazi", "Arrange nikah nama", "Prepare mehr amount", "Book baraat arrangements", "Arrange mehndi ceremony", "Book caterer for walima", "Prepare ijab-o-qubool", "Arrange rukhsati items", "Book salami band", "Prepare shaadi decorations"]
        case .bengaliHindu:
            return ["Book priest for biye", "Arrange gaye holud ceremony", "Book dhak players", "Arrange shankha-pola for bride", "Book sindoor daan items", "Arrange saptapadi items", "Book boubhat caterer", "Prepare sampradan items", "Arrange topor for groom", "Book nahabat players"]
        case .gujaratiMarwari:
            return ["Book priest", "Arrange garba/raas performers", "Book mehndi artist", "Arrange pithi ceremony items", "Book wedding thali decorator", "Prepare kansar/prasad", "Arrange mandvo decorations", "Book shehnai musicians", "Prepare vidai arrangements", "Arrange joota chupai"]
        case .christian:
            return ["Book church/venue", "Hire pastor/priest", "Book wedding band", "Arrange flowers for aisle", "Book wedding photographer", "Arrange bridal shower", "Book rehearsal dinner venue", "Prepare vows", "Arrange unity candle", "Book wedding car"]
        }
    }
}

enum RSVPStatus: String, Codable, CaseIterable {
    case pending = "Pending"
    case confirmed = "Confirmed"
    case declined = "Declined"
    case tentative = "Tentative"

    var color: Color {
        switch self {
        case .pending: return .orange
        case .confirmed: return .green
        case .declined: return .red
        case .tentative: return .yellow
        }
    }
}

enum VendorCategory: String, Codable, CaseIterable {
    case photographer = "Photography"
    case videographer = "Videography"
    case catering = "Catering"
    case decoration = "Decoration"
    case mehndi = "Mehndi Artist"
    case music = "Music/Band"
    case makeup = "Makeup & Hair"
    case priest = "Priest/Officiant"
    case venue = "Venue"
    case transport = "Transport"
    case invitation = "Invitations"
    case jewellery = "Jewellery"
    case clothing = "Clothing/Lehenga"
    case florist = "Florist"
    case other = "Other"

    var icon: String {
        switch self {
        case .photographer: return "camera.fill"
        case .videographer: return "video.fill"
        case .catering: return "fork.knife"
        case .decoration: return "sparkles"
        case .mehndi: return "hand.raised.fill"
        case .music: return "music.note"
        case .makeup: return "paintbrush.fill"
        case .priest: return "book.fill"
        case .venue: return "building.2.fill"
        case .transport: return "car.fill"
        case .invitation: return "envelope.fill"
        case .jewellery: return "star.fill"
        case .clothing: return "tag.fill"
        case .florist: return "leaf.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
}

enum BudgetCategory: String, Codable, CaseIterable {
    case venue = "Venue"
    case catering = "Catering"
    case decoration = "Decoration"
    case photography = "Photography"
    case music = "Music"
    case clothing = "Clothing"
    case jewellery = "Jewellery"
    case makeup = "Makeup"
    case invitations = "Invitations"
    case transport = "Transport"
    case accommodation = "Accommodation"
    case miscellaneous = "Miscellaneous"
}

enum FamilySide: String, Codable, CaseIterable {
    case bride = "Bride's Family"
    case groom = "Groom's Family"
    case shared = "Shared"
}

enum ShagunType: String, Codable, CaseIterable {
    case cash = "Cash"
    case cheque = "Cheque"
    case gift = "Gift"
    case jewelery = "Jewellery"
    case clothes = "Clothes"
    case online = "Online Transfer"
}

enum DietaryPreference: String, Codable, CaseIterable {
    case vegetarian = "Vegetarian"
    case nonVegetarian = "Non-Vegetarian"
    case vegan = "Vegan"
    case jain = "Jain"
    case glutenFree = "Gluten Free"
    case noRestriction = "No Restriction"
}

enum RelationshipSide: String, Codable, CaseIterable {
    case brideSide = "Bride's Side"
    case groomSide = "Groom's Side"
    case mutual = "Mutual Friends"
    case other = "Other"
}

// MARK: - Main Models

struct Wedding: Codable, Identifiable {
    var id: UUID = UUID()
    var brideName: String = ""
    var groomName: String = ""
    var weddingDate: Date = Date().addingTimeInterval(60 * 60 * 24 * 180)
    var venue: String = ""
    var city: String = ""
    var religion: Religion = .northIndianHindu
    var totalBudget: Double = 2000000
    var brideFamilyBudgetShare: Double = 50
    var notes: String = ""
    var createdAt: Date = Date()

    var groomFamilyBudgetShare: Double { 100 - brideFamilyBudgetShare }
    var daysUntilWedding: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: weddingDate).day ?? 0
    }
}

struct WeddingEvent: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var date: Date = Date()
    var startTime: Date = Date()
    var endTime: Date = Date().addingTimeInterval(4 * 3600)
    var venue: String = ""
    var venueAddress: String = ""
    var guestCapacity: Int = 100
    var notes: String = ""
    var color: String = "gold"
    var isCompleted: Bool = false
    var dressCode: String = ""
    var estimatedBudget: Double = 0

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: startTime)
    }
}

struct Guest: Codable, Identifiable {
    var id: UUID = UUID()
    var firstName: String
    var lastName: String
    var phone: String = ""
    var email: String = ""
    var householdId: UUID?
    var relationshipSide: RelationshipSide = .brideSide
    var relationship: String = ""
    var dietaryPreference: DietaryPreference = .vegetarian
    var rsvpStatus: RSVPStatus = .pending
    var eventsAttending: [UUID] = []
    var plusOne: Bool = false
    var plusOneName: String = ""
    var tableNumber: String = ""
    var notes: String = ""
    var whatsappOptIn: Bool = true
    var rsvpDate: Date?
    var city: String = ""
    var isVIP: Bool = false

    var fullName: String { "\(firstName) \(lastName)" }
    var initials: String {
        let f = firstName.prefix(1)
        let l = lastName.prefix(1)
        return "\(f)\(l)".uppercased()
    }
}

struct Household: Codable, Identifiable {
    var id: UUID = UUID()
    var familyName: String
    var headOfFamily: String = ""
    var phone: String = ""
    var address: String = ""
    var city: String = ""
    var relationshipSide: RelationshipSide = .brideSide
    var relationship: String = ""
    var memberIds: [UUID] = []
    var notes: String = ""
    var giftGiven: Bool = false
}

struct Vendor: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var category: VendorCategory
    var contactPerson: String = ""
    var phone: String = ""
    var email: String = ""
    var website: String = ""
    var address: String = ""
    var contractAmount: Double = 0
    var advancePaid: Double = 0
    var balanceDue: Double { contractAmount - totalPaid }
    var totalPaid: Double { paymentMilestones.filter { $0.isPaid }.reduce(0) { $0 + $1.amount } }
    var rating: Int = 0
    var isBooked: Bool = false
    var isContractSigned: Bool = false
    var contractNotes: String = ""
    var assignedEvents: [UUID] = []
    var paymentMilestones: [PaymentMilestone] = []
    var notes: String = ""
    var instagramHandle: String = ""
    var referredBy: String = ""
}

struct PaymentMilestone: Codable, Identifiable {
    var id: UUID = UUID()
    var description: String
    var amount: Double
    var dueDate: Date
    var isPaid: Bool = false
    var paidDate: Date?
    var paidBy: FamilySide = .bride
}

struct BudgetItem: Codable, Identifiable {
    var id: UUID = UUID()
    var title: String
    var category: BudgetCategory
    var eventId: UUID?
    var estimatedAmount: Double
    var actualAmount: Double = 0
    var paidAmount: Double = 0
    var paidBy: FamilySide = .shared
    var vendorId: UUID?
    var notes: String = ""
    var isApproved: Bool = false

    var remainingAmount: Double { estimatedAmount - paidAmount }
    var variance: Double { actualAmount - estimatedAmount }
}

struct ShagunEntry: Codable, Identifiable {
    var id: UUID = UUID()
    var fromName: String
    var fromGuestId: UUID?
    var fromHouseholdId: UUID?
    var amount: Double
    var shagunType: ShagunType
    var eventId: UUID?
    var description: String = ""
    var receivedDate: Date = Date()
    var thankYouSent: Bool = false
    var thankYouDate: Date?
    var notes: String = ""
    var isRecurring: Bool = false
    var relationshipSide: RelationshipSide = .brideSide
}

struct ChecklistItem: Codable, Identifiable {
    var id: UUID = UUID()
    var title: String
    var description: String = ""
    var category: String = ""
    var eventId: UUID?
    var dueDate: Date?
    var assignedTo: FamilySide = .shared
    var isCompleted: Bool = false
    var completedDate: Date?
    var priority: Priority = .medium
    var notes: String = ""

    enum Priority: String, Codable, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case urgent = "Urgent"

        var color: Color {
            switch self {
            case .low: return .green
            case .medium: return .blue
            case .high: return .orange
            case .urgent: return .red
            }
        }
    }
}

// MARK: - Color Theme

struct VivahTheme {
    static let gold = Color(red: 0.82, green: 0.68, blue: 0.21)
    static let marigold = Color(red: 0.97, green: 0.59, blue: 0.11)
    static let deepRed = Color(red: 0.65, green: 0.06, blue: 0.10)
    static let maroon = Color(red: 0.50, green: 0.05, blue: 0.10)
    static let ivory = Color(red: 0.98, green: 0.97, blue: 0.93)
    static let roseGold = Color(red: 0.91, green: 0.67, blue: 0.60)
    static let saffron = Color(red: 0.97, green: 0.53, blue: 0.08)
    static let forestGreen = Color(red: 0.13, green: 0.37, blue: 0.19)
    static let lightGold = Color(red: 0.98, green: 0.93, blue: 0.78)

    static var gradient: LinearGradient {
        LinearGradient(
            colors: [deepRed, maroon],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var goldGradient: LinearGradient {
        LinearGradient(
            colors: [gold, marigold],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

// MARK: - Currency Formatter

extension Double {
    var inrFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₹"
        formatter.currencyCode = "INR"
        formatter.maximumFractionDigits = 0
        formatter.locale = Locale(identifier: "en_IN")
        return formatter.string(from: NSNumber(value: self)) ?? "₹\(Int(self))"
    }

    var inrShortFormatted: String {
        if self >= 10_000_000 {
            return "₹\(String(format: "%.1f", self / 10_000_000))Cr"
        } else if self >= 100_000 {
            return "₹\(String(format: "%.1f", self / 100_000))L"
        } else if self >= 1000 {
            return "₹\(String(format: "%.1f", self / 1000))K"
        }
        return "₹\(Int(self))"
    }
}
