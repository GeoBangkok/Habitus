import Foundation
import SwiftUI
import Combine
import MapKit

// MARK: - Global App State
class AppState: ObservableObject {
    static let shared = AppState()

    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var savedProperties: [Property] = []
    @Published var unreadMessageCount = 0

    private init() {
        loadUser()
        checkAppleSignInStatus()
    }

    func loadUser() {
        // Load from UserDefaults or Keychain
        if let userData = UserDefaults.standard.data(forKey: "currentUser"),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            self.currentUser = user
            self.isAuthenticated = !user.isAnonymous
        }
    }

    func checkAppleSignInStatus() {
        // Check if user has signed in with Apple before
        if let appleUserID = KeychainHelper.shared.get(key: "appleUserID") {
            // User has signed in before, restore their session
            let email = KeychainHelper.shared.get(key: "userEmail")
            let name = KeychainHelper.shared.get(key: "userName")

            let user = User(
                id: appleUserID,
                email: email,
                name: name,
                profile: nil,
                savedPropertyIds: [],
                viewedPropertyIds: [],
                passedPropertyIds: [],
                createdAt: Date(),
                lastActiveAt: Date()
            )

            self.currentUser = user
            self.isAuthenticated = true
        } else if let guestID = KeychainHelper.shared.get(key: "guestUserID") {
            // Guest user
            let user = User(
                id: guestID,
                email: nil,
                name: "Guest",
                profile: nil,
                savedPropertyIds: [],
                viewedPropertyIds: [],
                passedPropertyIds: [],
                createdAt: Date(),
                lastActiveAt: Date()
            )

            self.currentUser = user
            self.isAuthenticated = false
        }
    }

    func signIn(user: User) {
        currentUser = user
        isAuthenticated = !user.isAnonymous
        // Save to UserDefaults/Keychain
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: "currentUser")
        }
    }

    func signOut() {
        currentUser = nil
        isAuthenticated = false
        savedProperties.removeAll()
        UserDefaults.standard.removeObject(forKey: "currentUser")
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")

        // Clear Keychain data
        KeychainHelper.shared.delete(key: "appleUserID")
        KeychainHelper.shared.delete(key: "userEmail")
        KeychainHelper.shared.delete(key: "userName")
        KeychainHelper.shared.delete(key: "guestUserID")
    }
}


// MARK: - Explore View Model
class ExploreViewModel: ObservableObject {
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 27.8006, longitude: -82.7946),
        span: MKCoordinateSpan(latitudeDelta: 1.0, longitudeDelta: 1.0)
    )
    @Published var visibleProperties: [Property] = []
    @Published var feedProperties: [Property] = []
    @Published var filters: PropertyFilters = PropertyFilters()
    @Published var shouldShowInsightCard = false
    @Published var userInsight = ""
    @Published var swipeCount = 0

    private let chatGPT = ChatGPTService.shared

    init() {
        loadFeed()
    }

    func loadFeed() {
        // Load properties based on user preferences
        // 50% matches, 30% inventory events, 20% taste expansion
        // For now, use empty array - will be populated by API
        feedProperties = []
        visibleProperties = feedProperties
    }

    func filterByCollection(_ collection: PropertyCollection) {
        // Apply collection filter
        // Update both map and feed
    }

    func saveProperty(_ property: Property) {
        AppState.shared.savedProperties.append(property)
        trackSwipe()
        checkForInsight()
    }

    func passProperty(_ property: Property) {
        trackSwipe()
        checkForInsight()
    }

    func messageAboutProperty(_ property: Property) {
        // Navigate to message composer
    }

    private func trackSwipe() {
        swipeCount += 1
    }

    private func checkForInsight() {
        if swipeCount == 3 && !shouldShowInsightCard {
            generateUserInsight()
            shouldShowInsightCard = true
        }
    }

    private func generateUserInsight() {
        // Analyze user behavior and generate insight
        userInsight = "You seem to like modern homes under $550k near Tampa. Want more like this?"
    }

    func applyInsightPreferences() {
        // Update filters based on insight
        shouldShowInsightCard = false
        loadFeed() // Reload with new preferences
    }

    func dismissInsight() {
        shouldShowInsightCard = false
    }
}

// MARK: - Saved View Model
class SavedViewModel: ObservableObject {
    @Published var savedProperties: [Property] = []
    @Published var shortlist: [Property] = []
    @Published var topPicks: [RankedProperty] = []
    @Published var isInDealMode = false

    private let chatGPT = ChatGPTService.shared

    init() {
        loadSavedProperties()
        checkDealMode()
    }

    func loadSavedProperties() {
        savedProperties = AppState.shared.savedProperties
    }

    private func checkDealMode() {
        // Check if user is in deal mode
        let recentSaves = savedProperties.filter { property in
            // Check if saved in last 7 days
            true
        }

        isInDealMode = recentSaves.count >= 5 ||
                      AppState.shared.currentUser?.profile?.timeline == .now

        if isInDealMode {
            generateShortlist()
        }
    }

    private func generateShortlist() {
        // Create shortlist and get AI rankings
        shortlist = Array(savedProperties.prefix(10))

        Task {
            if let profile = AppState.shared.currentUser?.profile {
                do {
                    let ranked = try await chatGPT.rankProperties(
                        shortlist,
                        userProfile: profile
                    )
                    await MainActor.run {
                        self.topPicks = Array(ranked.topPicks.prefix(3))
                    }
                } catch {
                    print("Failed to rank properties: \(error)")
                }
            }
        }
    }
}

// MARK: - Property Filters
struct PropertyFilters {
    var priceMin: Double?
    var priceMax: Double?
    var bedroomsMin: Int = 1
    var bathroomsMin: Double = 1
    var propertyTypes: [PropertyType] = PropertyType.allCases
    var cities: [String] = []
}

