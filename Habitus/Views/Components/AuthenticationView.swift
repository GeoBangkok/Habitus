import SwiftUI
import AuthenticationServices

struct AuthenticationView: View {
    let onComplete: (User) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var errorMessage: String?
    @State private var isSigningIn = false

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Logo and Title
                VStack(spacing: 16) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)

                    Text("Welcome to DreamHomes OS")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Sign in to save properties, get personalized recommendations, and message our team.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 40)

                Spacer()

                // Authentication Options
                VStack(spacing: 16) {
                    // Sign in with Apple
                    SignInWithAppleButton(
                        .signIn,
                        onRequest: { request in
                            request.requestedScopes = [.email, .fullName]
                            request.nonce = randomNonceString()
                        },
                        onCompletion: { result in
                            handleSignInResult(result)
                        }
                    )
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .cornerRadius(10)
                    .disabled(isSigningIn)

                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }

                    Text("or")
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)

                    // Continue as Guest
                    Button(action: continueAsGuest) {
                        HStack {
                            Image(systemName: "person.fill")
                            Text("Continue as Guest")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.gray.opacity(0.1))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                    }
                    .disabled(isSigningIn)
                }
                .padding(.horizontal)

                // Privacy Note
                Text("By signing in, you agree to our Terms of Service and Privacy Policy")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.bottom)
            }
            .navigationBarHidden(true)
            .overlay(
                Group {
                    if isSigningIn {
                        ProgressView("Signing in...")
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(10)
                            .shadow(radius: 5)
                    }
                }
            )
        }
    }

    private func handleSignInResult(_ result: Result<ASAuthorization, Error>) {
        isSigningIn = true
        errorMessage = nil

        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                // Store the user ID in Keychain for future logins
                let userID = appleIDCredential.user
                KeychainHelper.shared.save(userID, key: "appleUserID")

                // Get user details (only provided on first sign-in)
                let email = appleIDCredential.email
                let fullName = appleIDCredential.fullName

                // Check if we have stored user info (for returning users)
                var finalEmail = email
                var finalName = fullName?.formatted()

                if email == nil {
                    // Returning user - try to get stored info
                    finalEmail = KeychainHelper.shared.get(key: "userEmail")
                    finalName = KeychainHelper.shared.get(key: "userName")
                } else {
                    // First time user - store the info
                    if let email = email {
                        KeychainHelper.shared.save(email, key: "userEmail")
                    }
                    if let name = finalName {
                        KeychainHelper.shared.save(name, key: "userName")
                    }
                }

                // Create user object
                let user = User(
                    id: userID,
                    email: finalEmail,
                    name: finalName,
                    profile: nil,
                    savedPropertyIds: [],
                    viewedPropertyIds: [],
                    passedPropertyIds: [],
                    createdAt: Date(),
                    lastActiveAt: Date()
                )

                // Mark onboarding as completed
                UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")

                isSigningIn = false
                onComplete(user)
            }
        case .failure(let error):
            isSigningIn = false
            errorMessage = "Sign in failed. Please try again."
            print("Sign in with Apple failed: \(error)")
        }
    }

    private func continueAsGuest() {
        // Create anonymous user
        let guestID = UUID().uuidString
        KeychainHelper.shared.save(guestID, key: "guestUserID")

        let anonymousUser = User(
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

        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        onComplete(anonymousUser)
    }

    // Generate random nonce for security
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }

            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }

                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }

        return result
    }
}

// MARK: - Keychain Helper
class KeychainHelper {
    static let shared = KeychainHelper()

    private init() {}

    func save(_ value: String, key: String) {
        if let data = value.data(using: .utf8) {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: key,
                kSecValueData as String: data
            ]

            SecItemDelete(query as CFDictionary)
            SecItemAdd(query as CFDictionary, nil)
        }
    }

    func get(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        if status == noErr {
            if let data = dataTypeRef as? Data {
                return String(data: data, encoding: .utf8)
            }
        }
        return nil
    }

    func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]

        SecItemDelete(query as CFDictionary)
    }
}