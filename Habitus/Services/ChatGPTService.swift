import Foundation

// MARK: - ChatGPT API Service for GPT-5 nano
class ChatGPTService {
    static let shared = ChatGPTService()

    private var apiKey: String {
        APIConfig.openAIKey
    }
    private let baseURL = APIConfig.openAIBaseURL
    private let model = APIConfig.openAIModel

    // Cache for AI outputs
    private var insightCache: [String: CachedInsight] = [:]
    private let cacheExpiration: TimeInterval = 86400 // 24 hours

    private init() {}

    // MARK: - System Prompts
    private var systemPrompt: String {
        """
        You are DreamHomes OS.
        You never invent facts about a home.
        You only use data provided in context.
        If user asks for facts not provided, you say what you need (HOA, flood zone, etc).
        Keep outputs short, decisive, and numbered.
        For any claim, reference the input fields (price, beds, days_on_market, flood_risk, etc).
        """
    }

    // MARK: - Property Insight Generation
    func generatePropertyInsight(for property: Property) async throws -> String {
        // Check cache first
        let cacheKey = "insight_\(property.id)"
        if let cached = insightCache[cacheKey],
           Date().timeIntervalSince(cached.generatedAt) < cacheExpiration {
            return cached.content
        }

        let prompt = """
        Generate a brief insight (2-3 sentences) for this property:
        Price: \(property.formattedPrice)
        Location: \(property.city), FL
        Beds/Baths: \(property.bedrooms)/\(property.bathrooms)
        Days on Market: \(property.daysOnMarket)
        Deal Score: \(property.dealScore ?? 0)
        Flood Risk: \(property.floodRisk?.rawValue ?? "unknown")

        Focus on: Why this could be a deal, what to watch out for, or who this fits.
        """

        let response = try await callAPI(messages: [
            ChatMessage(role: .system, content: systemPrompt),
            ChatMessage(role: .user, content: prompt)
        ])

        // Cache the response
        insightCache[cacheKey] = CachedInsight(
            content: response,
            generatedAt: Date()
        )

        return response
    }

    // MARK: - Recommendation & Ranking
    func rankProperties(_ properties: [Property], userProfile: UserProfile) async throws -> RankedProperties {
        let propertiesInfo = properties.prefix(10).map { property in
            """
            ID: \(property.id)
            Price: \(property.formattedPrice)
            Location: \(property.city)
            Beds: \(property.bedrooms)
            Deal Score: \(property.dealScore ?? 0)
            Days on Market: \(property.daysOnMarket)
            """
        }.joined(separator: "\n---\n")

        let prompt = """
        User Goal: \(userProfile.goal.displayName)
        Timeline: \(userProfile.timeline.displayName)
        Budget: $\(Int(userProfile.budgetMin ?? 0)) - $\(Int(userProfile.budgetMax ?? 1000000))

        Properties to rank:
        \(propertiesInfo)

        Rank the top 3 properties. For each:
        1. Give 2 reasons why it's good
        2. Give 1 risk to consider

        Format: ID: [id] | Reasons: [r1, r2] | Risk: [risk]
        """

        let response = try await callAPI(messages: [
            ChatMessage(role: .system, content: systemPrompt),
            ChatMessage(role: .user, content: prompt)
        ])

        return parseRankedProperties(response, from: properties)
    }

    // MARK: - Message Assistance
    func rewriteMessage(_ originalMessage: String, for property: Property) async throws -> MessageSuggestion {
        let prompt = """
        Rewrite this message for a property inquiry:
        Original: "\(originalMessage)"
        Property: \(property.address), \(property.formattedPrice)

        Make it clear, professional, and effective. Keep it under 100 words.
        Also suggest 2 follow-up questions the buyer should ask.
        """

        let response = try await callAPI(messages: [
            ChatMessage(role: .system, content: systemPrompt),
            ChatMessage(role: .user, content: prompt)
        ])

        return parseMessageSuggestion(response)
    }

    // MARK: - Quick Q&A
    func askQuestion(_ question: String, context: SearchContext? = nil) async throws -> String {
        var contextInfo = ""
        if let context = context {
            contextInfo = """
            Context:
            - Saved properties: \(context.savedPropertyCount)
            - Recent searches: \(context.recentSearches.joined(separator: ", "))
            - Preferred locations: \(context.preferredLocations.joined(separator: ", "))
            """
        }

        let messages = [
            ChatMessage(role: .system, content: systemPrompt),
            ChatMessage(role: .user, content: """
                \(contextInfo)

                User Question: \(question)

                Answer concisely and reference specific data when available.
                """)
        ]

        return try await callAPI(messages: messages)
    }

    // MARK: - Core API Call
    private func callAPI(messages: [ChatMessage], stream: Bool = false) async throws -> String {
        var request = URLRequest(url: URL(string: "\(baseURL)/chat/completions")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody = ChatRequest(
            model: model,
            messages: messages,
            temperature: 0.7,
            max_tokens: 250, // Keep responses short for nano
            stream: stream
        )

        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }

        let chatResponse = try JSONDecoder().decode(ChatResponse.self, from: data)
        return chatResponse.choices.first?.message.content ?? ""
    }

    // MARK: - Parsing Helpers
    private func parseRankedProperties(_ response: String, from properties: [Property]) -> RankedProperties {
        // Parse the structured response
        // This is a simplified parser - enhance based on actual response format
        let lines = response.split(separator: "\n")
        var ranked: [RankedProperty] = []

        for line in lines {
            if line.contains("ID:") {
                // Parse each ranked property
                // Extract ID, reasons, and risk
                // Match with original properties
            }
        }

        return RankedProperties(
            topPicks: ranked,
            clarifyingQuestion: "Would you prefer newer construction or established neighborhoods?"
        )
    }

    private func parseMessageSuggestion(_ response: String) -> MessageSuggestion {
        // Parse rewritten message and follow-up questions
        let parts = response.split(separator: "\n")
        let rewritten = parts.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? response

        var questions: [String] = []
        for part in parts {
            if part.contains("?") {
                questions.append(String(part).trimmingCharacters(in: .whitespacesAndNewlines))
            }
        }

        return MessageSuggestion(
            rewrittenMessage: String(rewritten),
            followUpQuestions: Array(questions.prefix(2))
        )
    }
}

// MARK: - API Models
struct ChatRequest: Codable {
    let model: String
    let messages: [ChatMessage]
    let temperature: Double
    let max_tokens: Int
    let stream: Bool
}

struct ChatMessage: Codable {
    let role: Role
    let content: String

    enum Role: String, Codable {
        case system
        case user
        case assistant
    }
}

struct ChatResponse: Codable {
    let choices: [Choice]

    struct Choice: Codable {
        let message: ChatMessage
        let finish_reason: String?
    }
}

// MARK: - Response Models
struct RankedProperties {
    let topPicks: [RankedProperty]
    let clarifyingQuestion: String
}

struct RankedProperty: Identifiable {
    let id: String
    let property: Property
    let rank: Int
    let reasons: [String]
    let risk: String

    init(property: Property, rank: Int, reasons: [String], risk: String) {
        self.id = property.id
        self.property = property
        self.rank = rank
        self.reasons = reasons
        self.risk = risk
    }
}

struct MessageSuggestion {
    let rewrittenMessage: String
    let followUpQuestions: [String]
}

struct SearchContext {
    let savedPropertyCount: Int
    let recentSearches: [String]
    let preferredLocations: [String]
}

// MARK: - Cache Models
private struct CachedInsight {
    let content: String
    let generatedAt: Date
}

// MARK: - Error Handling
enum APIError: Error {
    case invalidResponse
    case rateLimited
    case invalidAPIKey
    case networkError(Error)

    var localizedDescription: String {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .rateLimited:
            return "Too many requests. Please try again later."
        case .invalidAPIKey:
            return "Invalid API key"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}