//
//  SwipeSpeakApp.swift
//  SwipeSpeak
//
//  Created by SwiftUI Migration on 22/06/2025.
//  Copyright © 2025 TeamGleason. All rights reserved.
//

import SwiftUI

@main
struct SwipeSpeakApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .preferredColorScheme(.light) // Match original app design
        }
    }
}

// MARK: - Main View (Temporary placeholder)

struct MainView: View {
    @State private var showingSettings = false
    @State private var showingHistory = false
    
    var body: some View {
        NavigationView {
            VStack {
                // Temporary placeholder - will be replaced with full implementation in Phase 2
                Text("SwipeSpeak")
                    .font(.largeTitle)
                    .padding()
                
                Text("SwiftUI Migration in Progress...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                
                Spacer()
                
                // Temporary buttons to test navigation
                VStack(spacing: 20) {
                    Button("Settings") {
                        showingSettings = true
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("History") {
                        showingHistory = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                
                Spacer()
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingHistory) {
                SentenceHistoryView()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle()) // Ensure single view on all devices
    }
}

// MARK: - Preview

#Preview {
    MainView()
}
