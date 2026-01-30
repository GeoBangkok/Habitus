import Foundation
import CoreLocation

// MARK: - Core Property Model
struct Property: Identifiable, Codable {
    let id: String
    let address: String
    let city: String
    let state: String = "FL"
    let zipCode: String
    let price: Double
    let bedrooms: Int
    let bathrooms: Double
    let squareFeet: Int?
    let lotSize: Double?
    let yearBuilt: Int?
    let propertyType: PropertyType
    let listingStatus: ListingStatus
    let daysOnMarket: Int
    let description: String?
    let imageUrls: [String]
    let coordinates: Coordinates
    let mlsNumber: String?

    // Analytics & Scoring
    let dealScore: Int? // 0-100
    let priceDropAmount: Double?
    let priceDropPercentage: Double?
    let estimatedRent: Double?
    let floodRisk: RiskLevel?
    let neighborhoodScore: Int?

    // AI Insights (cached)
    var aiInsight: String?
    var insightGeneratedAt: Date?

    var formattedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: price)) ?? "$\(Int(price))"
    }

    var mainImageUrl: String? {
        imageUrls.first
    }

    var badges: [PropertyBadge] {
        var badges: [PropertyBadge] = []

        if let score = dealScore, score > 80 {
            badges.append(.dealScore(score))
        }

        if let dropPercent = priceDropPercentage, dropPercent > 5 {
            badges.append(.priceDrop(dropPercent))
        }

        if let risk = floodRisk, risk == .low {
            badges.append(.lowFloodRisk)
        }

        if let rent = estimatedRent, rent > price * 0.007 {
            badges.append(.highRentalDemand)
        }

        return Array(badges.prefix(2)) // Max 2 badges as per spec
    }
}

struct Coordinates: Codable {
    let latitude: Double
    let longitude: Double

    var location: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

enum PropertyType: String, Codable, CaseIterable {
    case singleFamily = "single_family"
    case condo = "condo"
    case townhouse = "townhouse"
    case multiFamily = "multi_family"
    case land = "land"
    case other = "other"

    var displayName: String {
        switch self {
        case .singleFamily: return "Single Family"
        case .condo: return "Condo"
        case .townhouse: return "Townhouse"
        case .multiFamily: return "Multi-Family"
        case .land: return "Land"
        case .other: return "Other"
        }
    }
}

enum ListingStatus: String, Codable {
    case active = "active"
    case pending = "pending"
    case sold = "sold"
    case offMarket = "off_market"
    case comingSoon = "coming_soon"
}

enum RiskLevel: String, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case veryHigh = "very_high"
}

enum PropertyBadge {
    case dealScore(Int)
    case priceDrop(Double)
    case lowFloodRisk
    case highRentalDemand
    case newConstruction

    var text: String {
        switch self {
        case .dealScore(let score):
            return "Deal Score \(score)"
        case .priceDrop(let percent):
            return "Price Cut \(Int(percent))%"
        case .lowFloodRisk:
            return "Low Flood Risk"
        case .highRentalDemand:
            return "High Rental Demand"
        case .newConstruction:
            return "New Construction"
        }
    }

    var color: String {
        switch self {
        case .dealScore:
            return "green"
        case .priceDrop:
            return "red"
        case .lowFloodRisk:
            return "blue"
        case .highRentalDemand:
            return "purple"
        case .newConstruction:
            return "orange"
        }
    }
}