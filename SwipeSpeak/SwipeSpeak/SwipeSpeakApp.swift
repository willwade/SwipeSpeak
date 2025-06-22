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

// MARK: - Main View

struct MainView: View {
    @StateObject private var mainViewModel = MainViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // Navigation Bar
            NavigationBarView(viewModel: mainViewModel)

            // Text Display Area (sentence + word + predictions)
            TextDisplayView(viewModel: mainViewModel.textDisplayViewModel)
                .frame(maxWidth: .infinity)
                .frame(height: 200) // Fixed height for text display area

            // Keyboard Area - expand to fill remaining space
            KeyboardView(viewModel: mainViewModel.keyboardViewModel)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(.systemBackground))
        .onAppear {
            mainViewModel.onViewDidAppear()
        }
        .sheet(isPresented: $mainViewModel.showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $mainViewModel.showingHistory) {
            SentenceHistoryView()
        }
    }
}

// MARK: - Navigation Bar

struct NavigationBarView: View {
    @ObservedObject var viewModel: MainViewModel

    var body: some View {
        HStack {
            // Settings Button
            Button("Settings") {
                viewModel.presentSettings()
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.blue)
            .accessibilityLabel("Settings")
            .accessibilityHint("Open app settings")

            Spacer()

            // App Title
            Text("SwipeSpeak")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            Spacer()

            // History Button
            Button("History") {
                viewModel.presentHistory()
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.blue)
            .accessibilityLabel("History")
            .accessibilityHint("View sentence history")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .fill(Color(.separator))
                .frame(height: 0.5),
            alignment: .bottom
        )
    }
}

// MARK: - Preview

#Preview {
    MainView()
}
