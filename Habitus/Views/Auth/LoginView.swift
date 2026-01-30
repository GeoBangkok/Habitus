import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @StateObject private var appState = AppState.shared
    @State private var showingOnboarding = false
    @State private var isSigningIn = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.1),
                    Color.white
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo and App Name
                VStack(spacing: 20) {
                    Image(systemName: "building.2.crop.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .blue.opacity(0.7)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    VStack(spacing: 8) {
                        Text("DreamHomes OS")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("Private Florida Opportunities")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Sign In Section
                VStack(spacing: 20) {
                    // Apple Sign In
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
                    .frame(height: 54)
                    .cornerRadius(12)
                    .disabled(isSigningIn)

                    // OR Divider
                    HStack {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 1)

                        Text("OR")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 10)

                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 1)
                    }

                    // Browse as Guest Button
                    Button(action: browseAsGuest) {
                        HStack {
                            Image(systemName: "eye")
                                .font(.title3)
                            Text("Browse as Guest")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.gray.opacity(0.1))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                    }
                    .disabled(isSigningIn)

                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 30)

                Spacer()

                // Footer
                VStack(spacing: 8) {
                    Text("By continuing, you agree to our")
                        .font(.caption2)
                        .foregroundColor(.gray)

                    HStack(spacing: 4) {
                        Button("Terms of Service") {
                            // Open terms
                        }
                        .font(.caption2)
                        .foregroundColor(.blue)

                        Text("and")
                            .font(.caption2)
                            .foregroundColor(.gray)

                        Button("Privacy Policy") {
                            // Open privacy
                        }
                        .font(.caption2)
                        .foregroundColor(.blue)
                    }
                }
                .padding(.bottom, 30)
            }

            if isSigningIn {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()

                ProgressView("Signing in...")
                    .padding(20)
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 10)
            }
        }
        .fullScreenCover(isPresented: $showingOnboarding) {
            OnboardingQualificationView()
        }
    }

    private func handleSignInResult(_ result: Result<ASAuthorization, Error>) {
        isSigningIn = true
        errorMessage = nil

        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                let userID = appleIDCredential.user
                KeychainHelper.shared.save(userID, key: "appleUserID")

                let email = appleIDCredential.email
                let fullName = appleIDCredential.fullName

                var finalEmail = email
                var finalName = fullName?.formatted()

                if email == nil {
                    finalEmail = KeychainHelper.shared.get(key: "userEmail")
                    finalName = KeychainHelper.shared.get(key: "userName")
                } else {
                    if let email = email {
                        KeychainHelper.shared.save(email, key: "userEmail")
                    }
                    if let name = finalName {
                        KeychainHelper.shared.save(name, key: "userName")
                    }
                }

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

                appState.signIn(user: user)
                isSigningIn = false
                showingOnboarding = true
            }
        case .failure(let error):
            isSigningIn = false
            errorMessage = "Sign in failed. Please try again."
            print("Sign in with Apple failed: \(error)")
        }
    }

    private func browseAsGuest() {
        let guestID = UUID().uuidString
        KeychainHelper.shared.save(guestID, key: "guestUserID")

        let guest = User(
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

        appState.signIn(user: guest)
        showingOnboarding = true
    }
}

#Preview {
    LoginView()
}