import Foundation

// MARK: - API Configuration
// IMPORTANT: Never commit real API keys to source control

struct APIConfig {
    // For development, set these as environment variables in your Xcode scheme:
    // 1. Edit Scheme → Run → Arguments → Environment Variables
    // 2. Add: OPENAI_API_KEY = your_actual_key_here

    static var openAIKey: String {
        #if DEBUG
        // Development - read from environment or use test key
        return ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? "test_key_for_development"
        #else
        // Production - read from secure storage
        return KeychainService.shared.getAPIKey(for: "openai") ?? ""
        #endif
    }

    static let openAIModel = "gpt-5-nano" // Using GPT-5 nano for speed and cost efficiency
    static let openAIBaseURL = "https://api.openai.com/v1"
}

// MARK: - Keychain Service (Stub)
// In production, implement proper Keychain storage
class KeychainService {
    static let shared = KeychainService()

    func getAPIKey(for service: String) -> String? {
        // Implement secure keychain retrieval
        return nil
    }

    func setAPIKey(_ key: String, for service: String) {
        // Implement secure keychain storage
    }
}