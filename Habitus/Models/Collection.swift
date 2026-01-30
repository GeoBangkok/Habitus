import Foundation

// MARK: - Property Collections
struct PropertyCollection: Identifiable {
    let id: String
    let title: String
    let subtitle: String?
    let icon: String
    let filter: CollectionFilter
    let updatedAt: Date
    let propertyCount: Int

    var updatedText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return "Updated \(formatter.localizedString(for: updatedAt, relativeTo: Date()))"
    }

    static let defaultCollections: [PropertyCollection] = [
        PropertyCollection(
            id: "best_value",
            title: "Best Value This Week",
            subtitle: "Top deals based on market analysis",
            icon: "star.fill",
            filter: .bestValue,
            updatedAt: Date().addingTimeInterval(-86400),
            propertyCount: 12
        ),
        PropertyCollection(
            id: "price_drops",
            title: "Price Drops",
            subtitle: "Recent reductions",
            icon: "arrow.down.circle.fill",
            filter: .priceDrops,
            updatedAt: Date().addingTimeInterval(-43200),
            propertyCount: 8
        ),
        PropertyCollection(
            id: "family_safe",
            title: "Family Safe Picks",
            subtitle: "Great schools, low crime",
            icon: "house.fill",
            filter: .familySafe,
            updatedAt: Date().addingTimeInterval(-172800),
            propertyCount: 15
        ),
        PropertyCollection(
            id: "rental_friendly",
            title: "Rental Friendly",
            subtitle: "High rental demand areas",
            icon: "building.2.fill",
            filter: .rentalFriendly,
            updatedAt: Date().addingTimeInterval(-86400),
            propertyCount: 10
        ),
        PropertyCollection(
            id: "new_construction",
            title: "New Construction Watch",
            subtitle: "Brand new homes",
            icon: "hammer.fill",
            filter: .newConstruction,
            updatedAt: Date().addingTimeInterval(-259200),
            propertyCount: 6
        ),
        PropertyCollection(
            id: "waterfront",
            title: "Waterfront Risk-Checked",
            subtitle: "Beautiful views, verified safety",
            icon: "drop.fill",
            filter: .waterfront,
            updatedAt: Date().addingTimeInterval(-86400),
            propertyCount: 7
        )
    ]
}

enum CollectionFilter {
    case bestValue
    case priceDrops
    case familySafe
    case rentalFriendly
    case newConstruction
    case quietNeighborhoods
    case waterfront

    var queryParameters: [String: Any] {
        switch self {
        case .bestValue:
            return ["dealScore": ["$gte": 80]]
        case .priceDrops:
            return ["priceDropPercentage": ["$gte": 5]]
        case .familySafe:
            return ["neighborhoodScore": ["$gte": 75], "floodRisk": ["$ne": "high"]]
        case .rentalFriendly:
            return ["rentalYield": ["$gte": 0.007]]
        case .newConstruction:
            return ["yearBuilt": ["$gte": 2023]]
        case .quietNeighborhoods:
            return ["neighborhoodNoise": ["$lte": 3]]
        case .waterfront:
            return ["waterfront": true, "floodRisk": ["$ne": "very_high"]]
        }
    }
}