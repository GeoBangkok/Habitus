//
//  ContentView.swift
//  DreamHomes OS
//
//  Created by standard on 1/29/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var appState = AppState.shared
    @State private var showOnboarding = true

    var body: some View {
        Group {
            if showOnboarding && !appState.isAuthenticated {
                OnboardingView()
                    .environmentObject(appState)
            } else {
                MainTabView()
                    .environmentObject(appState)
            }
        }
        .onAppear {
            // Check if user has completed onboarding
            checkOnboardingStatus()
        }
    }

    private func checkOnboardingStatus() {
        // Check if user has seen onboarding before
        let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")

        // If authenticated or has completed onboarding, skip to main app
        if appState.isAuthenticated || hasCompletedOnboarding {
            showOnboarding = false
        }
    }
}

#Preview {
    ContentView()
}
