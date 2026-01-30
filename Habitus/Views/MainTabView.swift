import SwiftUI

struct MainTabView: View {
    @StateObject private var appState = AppState.shared
    @State private var selectedTab = 0
    @State private var showingAskSheet = false

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                // Explore Tab
                ExploreView()
                    .tabItem {
                        Label("Explore", systemImage: "map")
                    }
                    .tag(0)

                // Saved Tab
                SavedView()
                    .tabItem {
                        Label("Saved", systemImage: "heart.fill")
                    }
                    .tag(1)
                    .badge(appState.savedProperties.count)

                // Inbox Tab
                InboxView()
                    .tabItem {
                        Label("Inbox", systemImage: "message.fill")
                    }
                    .tag(2)
                    .badge(appState.unreadMessageCount)

                // Profile Tab
                ProfileView()
                    .tabItem {
                        Label("Profile", systemImage: "person.fill")
                    }
                    .tag(3)
            }

            // Floating Ask Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        showingAskSheet = true
                    }) {
                        HStack {
                            Image(systemName: "sparkles")
                            Text("Ask DreamHomes OS")
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(25)
                        .shadow(radius: 5)
                    }
                    .padding()
                }
            }
        }
        .sheet(isPresented: $showingAskSheet) {
            AskAssistantView()
        }
    }
}

// MARK: - Explore View
struct ExploreView: View {
    @State private var exploreMode: ExploreMode = .browse
    @State private var showingModeSelector = false

    enum ExploreMode: String, CaseIterable {
        case swipe = "Swipe"
        case browse = "Browse"

        var icon: String {
            switch self {
            case .swipe: return "square.stack.3d.up.fill"
            case .browse: return "square.grid.2x2"
            }
        }

        var description: String {
            switch self {
            case .swipe: return "Tinder-style swiping"
            case .browse: return "Map and grid view"
            }
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Mode Selector Bar
                HStack {
                    Text("Explore")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Spacer()

                    Button(action: { showingModeSelector = true }) {
                        HStack {
                            Image(systemName: exploreMode.icon)
                            Text(exploreMode.rawValue)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                    }
                }
                .padding()

                // Content based on mode
                Group {
                    switch exploreMode {
                    case .swipe:
                        SwipeModeView()
                    case .browse:
                        BrowseModeView()
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .actionSheet(isPresented: $showingModeSelector) {
            ActionSheet(
                title: Text("Choose Explore Mode"),
                message: Text("How would you like to browse properties?"),
                buttons: [
                    .default(Text("🃏 Swipe Mode - Tinder-style cards")) {
                        exploreMode = .swipe
                    },
                    .default(Text("🗺 Browse Mode - Map and grid")) {
                        exploreMode = .browse
                    },
                    .cancel()
                ]
            )
        }
    }
}

// MARK: - Saved View
struct SavedView: View {
    @StateObject private var viewModel = SavedViewModel()
    @State private var showingCompare = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Shortlist Section (Deal Mode)
                    if viewModel.isInDealMode {
                        DealModeSection(
                            shortlist: viewModel.shortlist,
                            topPicks: viewModel.topPicks
                        )
                    }

                    // Saved Properties
                    Text("Saved Properties")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(viewModel.savedProperties) { property in
                            SavedPropertyCard(property: property)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Saved")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Compare") {
                        showingCompare = true
                    }
                    .disabled(viewModel.savedProperties.count < 2)
                }
            }
        }
        .sheet(isPresented: $showingCompare) {
            ComparePropertiesView(properties: viewModel.savedProperties)
        }
    }
}

// MARK: - Inbox View
struct InboxView: View {
    @StateObject private var viewModel = InboxViewModel()

    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.conversations) { conversation in
                    NavigationLink(destination: ConversationView(conversation: conversation)) {
                        ConversationRow(conversation: conversation)
                    }
                }
            }
            .navigationTitle("Inbox")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
        }
    }
}

// MARK: - Profile View
struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showingSettings = false

    var body: some View {
        NavigationView {
            Form {
                // User Info Section
                Section {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)

                        VStack(alignment: .leading) {
                            Text(viewModel.userName)
                                .font(.title3)
                                .fontWeight(.medium)

                            Text(viewModel.userEmail)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.leading)
                    }
                    .padding(.vertical, 8)
                }

                // Profile Settings
                Section("Preferences") {
                    HStack {
                        Text("Timeline")
                        Spacer()
                        Picker("Timeline", selection: $viewModel.timeline) {
                            ForEach(UserProfile.Timeline.allCases, id: \.self) { timeline in
                                Text(timeline.displayName).tag(timeline)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }

                    HStack {
                        Text("Goal")
                        Spacer()
                        Picker("Goal", selection: $viewModel.goal) {
                            ForEach(UserProfile.Goal.allCases, id: \.self) { goal in
                                Text(goal.displayName).tag(goal)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }

                    HStack {
                        Text("Budget")
                        Spacer()
                        Text(viewModel.budgetRange)
                            .foregroundColor(.secondary)
                    }
                }

                // Stats Section
                Section("Activity") {
                    StatRow(title: "Properties Viewed", value: "\(viewModel.viewedCount)")
                    StatRow(title: "Properties Saved", value: "\(viewModel.savedCount)")
                    StatRow(title: "Messages Sent", value: "\(viewModel.messageCount)")
                    StatRow(title: "Tours Requested", value: "\(viewModel.tourCount)")
                }

                // Settings
                Section {
                    Button(action: { showingSettings = true }) {
                        Label("Settings", systemImage: "gear")
                    }

                    Button(action: { viewModel.signOut() }) {
                        Label("Sign Out", systemImage: "arrow.right.square")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Profile")
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }
}

// MARK: - Helper Views
struct MicroInsightCard: View {
    let insight: String
    let onYes: () -> Void
    let onKeepBrowsing: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.blue)
                Text("DreamHomes OS noticed:")
                    .fontWeight(.medium)
            }

            Text(insight)
                .font(.subheadline)
                .multilineTextAlignment(.center)

            HStack(spacing: 12) {
                Button("Yes, show me more", action: onYes)
                    .buttonStyle(.borderedProminent)

                Button("Keep browsing", action: onKeepBrowsing)
                    .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(12)
    }
}

struct DealModeSection: View {
    let shortlist: [Property]
    let topPicks: [RankedProperty]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Deal Mode Active", systemImage: "target")
                .font(.headline)
                .foregroundColor(.green)

            Text("Top 3 Picks")
                .font(.title3)
                .fontWeight(.bold)

            ForEach(topPicks) { pick in
                DealPickCard(rankedProperty: pick)
            }

            Button(action: {}) {
                Label("View Full Shortlist", systemImage: "list.bullet")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(Color.green.opacity(0.05))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct StatRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
                .fontWeight(.medium)
        }
    }
}