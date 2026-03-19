import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: WeddingStore
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }
                .tag(0)

            EventsView()
                .tabItem {
                    Label("Events", systemImage: "calendar")
                }
                .tag(1)

            GuestManagementView()
                .tabItem {
                    Label("Guests", systemImage: "person.2.fill")
                }
                .tag(2)

            BudgetView()
                .tabItem {
                    Label("Budget", systemImage: "indianrupeesign.circle.fill")
                }
                .tag(3)

            MoreMenuView()
                .tabItem {
                    Label("More", systemImage: "ellipsis.circle.fill")
                }
                .tag(4)
        }
        .tint(VivahTheme.deepRed)
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.systemBackground
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

struct MoreMenuView: View {
    @EnvironmentObject var store: WeddingStore
    @State private var showVendors = false
    @State private var showShagun = false
    @State private var showChecklist = false
    @State private var showDayOf = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        VendorManagementView()
                            .environmentObject(store)
                    } label: {
                        MoreMenuRow(
                            icon: "briefcase.fill",
                            title: "Vendors",
                            subtitle: "\(store.vendorsBooked) booked",
                            color: VivahTheme.gold
                        )
                    }

                    NavigationLink {
                        ShagunTrackerView()
                            .environmentObject(store)
                    } label: {
                        MoreMenuRow(
                            icon: "gift.fill",
                            title: "Shagun & Gifts",
                            subtitle: store.totalShagunAmount.inrShortFormatted + " received",
                            color: VivahTheme.marigold
                        )
                    }

                    NavigationLink {
                        ChecklistView()
                            .environmentObject(store)
                    } label: {
                        MoreMenuRow(
                            icon: "checkmark.circle.fill",
                            title: "Checklist",
                            subtitle: "\(store.completedChecklistCount)/\(store.checklistItems.count) done",
                            color: VivahTheme.forestGreen
                        )
                    }

                    NavigationLink {
                        DayOfView()
                            .environmentObject(store)
                    } label: {
                        MoreMenuRow(
                            icon: "sparkles",
                            title: "Day-Of Dashboard",
                            subtitle: "Coordination timeline",
                            color: VivahTheme.deepRed
                        )
                    }
                } header: {
                    Text("Tools")
                }

                Section {
                    HStack {
                        Image(systemName: "person.2.fill")
                            .foregroundColor(VivahTheme.gold)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(store.wedding.brideName) & \(store.wedding.groomName)")
                                .font(.subheadline).fontWeight(.semibold)
                            Text(store.wedding.religion.rawValue)
                                .font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        Text("\(store.wedding.daysUntilWedding) days")
                            .font(.caption)
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(VivahTheme.deepRed.opacity(0.1))
                            .foregroundColor(VivahTheme.deepRed)
                            .cornerRadius(8)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Wedding Details")
                }
            }
            .navigationTitle("More")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct MoreMenuRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 16))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline).fontWeight(.semibold)
                Text(subtitle)
                    .font(.caption).foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
