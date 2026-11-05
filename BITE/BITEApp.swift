//
//  BITEApp.swift
//  BITE
//
//  Created by Fatima on 03/11/2026.
//

import SwiftUI

@main
struct BITEApp: App {
    @StateObject private var app = AppState()

    init() {
        PantryNotifications.configureForegroundDelivery()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if app.profile.onboarded {
                    MainTabView()
                } else {
                    OnboardingFlow()
                }
            }
            .environmentObject(app)
            .preferredColorScheme(.light)
            .task { await app.refreshRecipes() }
        }
    }
}
