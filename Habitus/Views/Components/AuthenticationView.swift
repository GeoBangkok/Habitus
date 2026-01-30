import SwiftUI
import AuthenticationServices

struct AuthenticationView: View {
    let onComplete: (User) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Logo and Title
                VStack(spacing: 16) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)

                    Text("Save your favorites")
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
                        },
                        onCompletion: { result in
                            handleSignInResult(result)
                        }
                    )
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .cornerRadius(10)

                    // Continue with Google
                    Button(action: signInWithGoogle) {
                        HStack {
                            Image(systemName: "globe")
                            Text("Continue with Google")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }

                    // Continue with Email
                    Button(action: signInWithEmail) {
                        HStack {
                            Image(systemName: "envelope")
                            Text("Continue with Email")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.gray.opacity(0.1))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal)

                // Not Now Option
                Button("Not now") {
                    // Create anonymous user
                    let anonymousUser = User(
                        id: UUID().uuidString,
                        email: nil,
                        name: nil,
                        profile: nil,
                        savedPropertyIds: [],
                        viewedPropertyIds: [],
                        passedPropertyIds: [],
                        createdAt: Date(),
                        lastActiveAt: Date()
                    )
                    onComplete(anonymousUser)
                }
                .foregroundColor(.secondary)
                .padding(.bottom)
            }
            .navigationBarHidden(true)
        }
    }

    private func handleSignInResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                let user = User(
                    id: appleIDCredential.user,
                    email: appleIDCredential.email,
                    name: appleIDCredential.fullName?.formatted(),
                    profile: nil,
                    savedPropertyIds: [],
                    viewedPropertyIds: [],
                    passedPropertyIds: [],
                    createdAt: Date(),
                    lastActiveAt: Date()
                )
                onComplete(user)
            }
        case .failure(let error):
            print("Sign in with Apple failed: \(error)")
        }
    }

    private func signInWithGoogle() {
        // Implement Google Sign-In
        // For now, create a mock user
        let user = User(
            id: UUID().uuidString,
            email: "user@gmail.com",
            name: "Google User",
            profile: nil,
            savedPropertyIds: [],
            viewedPropertyIds: [],
            passedPropertyIds: [],
            createdAt: Date(),
            lastActiveAt: Date()
        )
        onComplete(user)
    }

    private func signInWithEmail() {
        // Navigate to email sign in flow
        // For now, create a mock user
        let user = User(
            id: UUID().uuidString,
            email: "user@email.com",
            name: "Email User",
            profile: nil,
            savedPropertyIds: [],
            viewedPropertyIds: [],
            passedPropertyIds: [],
            createdAt: Date(),
            lastActiveAt: Date()
        )
        onComplete(user)
    }
}