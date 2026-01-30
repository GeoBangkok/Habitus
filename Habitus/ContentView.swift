//
//  ContentView.swift
//  DreamHomes OS
//
//  Created by standard on 1/29/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var appState = AppState.shared
    @State private var showLogin = true
    @State private var showOnboarding = false

    var body: some View {
        Group {
            if !appState.isAuthenticated && showLogin {
                // Show login screen for new users
                LoginView()
                    .environmentObject(appState)
            } else if showOnboarding && !hasCompletedOnboarding() {
                // Show onboarding qualification after login
                OnboardingQualificationView()
                    .environmentObject(appState)
            } else {
                // Show main app
                MainTabView()
                    .environmentObject(appState)
            }
        }
        .onAppear {
            checkAuthStatus()
        }
        .onReceive(appState.$isAuthenticated) { isAuthenticated in
            if isAuthenticated {
                showLogin = false
                showOnboarding = !hasCompletedOnboarding()
            }
        }
    }

    private func checkAuthStatus() {
        // Check if user has authenticated before
        if appState.isAuthenticated || KeychainHelper.shared.get(key: "appleUserID") != nil {
            showLogin = false
            showOnboarding = false
        }
    }

    private func hasCompletedOnboarding() -> Bool {
        UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }
}

#Preview {
    ContentView()
}
