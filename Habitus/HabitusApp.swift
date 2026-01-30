//
//  HabitusApp.swift
//  DreamHomes OS
//
//  Created by standard on 1/29/26.
//

import SwiftUI

@main
struct DreamHomesApp: App {
    @StateObject private var appState = AppState.shared
    @State private var showOnboarding = true

    var body: some Scene {
        WindowGroup {
            if showOnboarding && !appState.isAuthenticated {
                OnboardingView()
                    .environmentObject(appState)
            } else {
                MainTabView()
                    .environmentObject(appState)
            }
        }
    }
}
