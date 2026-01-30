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
    }

    func loadUser() {
        // Load from UserDefaults or Keychain
        if let userData = UserDefaults.standard.data(forKey: "currentUser"),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            self.currentUser = user
            self.isAuthenticated = !user.isAnonymous
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
    }
}

// MARK: - Onboarding View Model
class OnboardingViewModel: ObservableObject {
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 27.8006, longitude: -82.7946), // Florida center
        span: MKCoordinateSpan(latitudeDelta: 2.0, longitudeDelta: 2.0)
    )
    @Published var visibleProperties: [Property] = []
    @Published var savedProperties: [Property] = []
    @Published var passedProperties: [Property] = []
    @Published var hasInteracted = false
    @Published var isAuthenticated = false
    @Published var sessionDuration: TimeInterval = 0
    @Published var detailViewCount = 0

    private var sessionStart = Date()
    private var timer: Timer?

    init() {
        loadProperties()
        startSessionTimer()
    }

    func loadProperties() {
        // Mock data - replace with actual API call
        visibleProperties = MockData.sampleProperties
    }

    func filterByCollection(_ collection: PropertyCollection) {
        // Apply collection filter to properties
        // This would typically call an API with the filter parameters
        hasInteracted = true
    }

    func saveProperty(_ property: Property) {
        if !savedProperties.contains(where: { $0.id == property.id }) {
            savedProperties.append(property)
            hasInteracted = true
            trackAction(.save, property: property)
        }
    }

    func passProperty(_ property: Property) {
        if !passedProperties.contains(where: { $0.id == property.id }) {
            passedProperties.append(property)
            hasInteracted = true
            trackAction(.pass, property: property)
        }
    }

    func authenticateUser(_ user: User) {
        isAuthenticated = true
        AppState.shared.signIn(user: user)
    }

    private func trackAction(_ action: UserAction.ActionType, property: Property) {
        // Track user action for personalization
        let action = UserAction(
            id: UUID().uuidString,
            userId: AppState.shared.currentUser?.id ?? "anonymous",
            propertyId: property.id,
            action: action,
            timestamp: Date(),
            metadata: nil
        )
        // Send to backend
    }

    private func startSessionTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            self.sessionDuration = Date().timeIntervalSince(self.sessionStart)
        }
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
        feedProperties = MockData.sampleProperties
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

// MARK: - Mock Data
struct MockData {
    static let sampleProperties: [Property] = [
        Property(
            id: "1",
            address: "123 Ocean Drive",
            city: "Miami Beach",
            zipCode: "33139",
            price: 550000,
            bedrooms: 3,
            bathrooms: 2.5,
            squareFeet: 2200,
            lotSize: 0.25,
            yearBuilt: 2019,
            propertyType: .singleFamily,
            listingStatus: .active,
            daysOnMarket: 15,
            description: "Modern beachfront home with stunning ocean views",
            imageUrls: ["https://example.com/image1.jpg"],
            coordinates: Coordinates(latitude: 25.7617, longitude: -80.1918),
            mlsNumber: "A12345",
            dealScore: 85,
            priceDropAmount: 25000,
            priceDropPercentage: 4.3,
            estimatedRent: 4500,
            floodRisk: .low,
            neighborhoodScore: 88,
            aiInsight: nil,
            insightGeneratedAt: nil
        ),
        Property(
            id: "2",
            address: "456 Tampa Bay Blvd",
            city: "Tampa",
            zipCode: "33602",
            price: 425000,
            bedrooms: 4,
            bathrooms: 3,
            squareFeet: 2800,
            lotSize: 0.3,
            yearBuilt: 2021,
            propertyType: .singleFamily,
            listingStatus: .active,
            daysOnMarket: 8,
            description: "New construction in family-friendly neighborhood",
            imageUrls: ["https://example.com/image2.jpg"],
            coordinates: Coordinates(latitude: 27.9506, longitude: -82.4572),
            mlsNumber: "B67890",
            dealScore: 92,
            priceDropAmount: nil,
            priceDropPercentage: nil,
            estimatedRent: 3800,
            floodRisk: .low,
            neighborhoodScore: 91,
            aiInsight: nil,
            insightGeneratedAt: nil
        )
    ]
}