import Foundation

// MARK: - User Models
struct User: Codable {
    let id: String
    let email: String?
    let name: String?
    let profile: UserProfile?
    let savedPropertyIds: [String]
    let viewedPropertyIds: [String]
    let passedPropertyIds: [String]
    let createdAt: Date
    let lastActiveAt: Date

    var isAnonymous: Bool {
        email == nil
    }
}

struct UserProfile: Codable {
    let timeline: Timeline
    let goal: Goal
    let budgetMin: Double?
    let budgetMax: Double?
    let preferredLocations: [String]
    let preferredPropertyTypes: [PropertyType]

    enum Timeline: String, Codable, CaseIterable {
        case now = "now"
        case threeToTwelve = "3_12_months"
        case browsing = "browsing"

        var displayName: String {
            switch self {
            case .now: return "Ready now"
            case .threeToTwelve: return "3-12 months"
            case .browsing: return "Just browsing"
            }
        }
    }

    enum Goal: String, Codable, CaseIterable {
        case live = "live"
        case rent = "rent"
        case both = "both"

        var displayName: String {
            switch self {
            case .live: return "Live in"
            case .rent: return "Rent out"
            case .both: return "Both"
            }
        }
    }
}

// MARK: - User Actions
struct UserAction: Codable {
    let id: String
    let userId: String
    let propertyId: String
    let action: ActionType
    let timestamp: Date
    let metadata: [String: String]?

    enum ActionType: String, Codable {
        case view = "view"
        case save = "save"
        case pass = "pass"
        case message = "message"
        case requestTour = "request_tour"
        case share = "share"
    }
}