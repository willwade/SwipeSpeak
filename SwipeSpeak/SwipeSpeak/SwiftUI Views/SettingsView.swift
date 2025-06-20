//
//  SettingsView.swift
//  SwipeSpeak
//
//  Created by SwiftUI Migration on 20/01/2025.
//  Copyright © 2025 TeamGleason. All rights reserved.
//

import SwiftUI
import AVFoundation

/// SwiftUI Settings View - First hybrid implementation
struct SettingsView: View {
    
    @StateObject private var viewModel = SettingsViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                keyboardSection
                speechSection
                feedbackSection
                predictionSection
                cloudSection
                aboutSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Keyboard Section
    
    private var keyboardSection: some View {
        Section("Keyboard Layout") {
            Picker("Layout", selection: Binding(
                get: { viewModel.currentKeyboardLayout },
                set: { viewModel.updateKeyboardLayout($0) }
            )) {
                ForEach(viewModel.availableLayouts, id: \.self) { layout in
                    Text(layout.displayName)
                        .tag(layout)
                }
            }
            .pickerStyle(.menu)
            
            NavigationLink("Keyboard Settings") {
                KeyboardSettingsView()
            }
        }
    }
    
    // MARK: - Speech Section
    
    private var speechSection: some View {
        Section("Speech") {
            VStack(alignment: .leading, spacing: 8) {
                Text("Speech Rate")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text("Slow")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Slider(
                        value: Binding(
                            get: { viewModel.currentSpeechRate },
                            set: { viewModel.updateSpeechRate($0) }
                        ),
                        in: 0.1...1.0,
                        step: 0.1
                    )
                    
                    Text("Fast")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Volume")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Image(systemName: "speaker.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Slider(
                        value: Binding(
                            get: { viewModel.currentSpeechVolume },
                            set: { viewModel.updateSpeechVolume($0) }
                        ),
                        in: 0.0...1.0,
                        step: 0.1
                    )
                    
                    Image(systemName: "speaker.wave.3.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
            
            NavigationLink("Voice Selection") {
                VoiceSelectionView()
            }
            
            Button("Test Speech") {
                Task {
                    await viewModel.testSpeech()
                }
            }
            .foregroundColor(.blue)
        }
    }
    
    // MARK: - Feedback Section
    
    private var feedbackSection: some View {
        Section("Feedback") {
            Toggle("Audio Feedback", isOn: Binding(
                get: { viewModel.isAudioFeedbackEnabled },
                set: { _ in viewModel.toggleAudioFeedback() }
            ))
            
            Toggle("Vibration", isOn: Binding(
                get: { viewModel.isVibrationEnabled },
                set: { _ in viewModel.toggleVibration() }
            ))
            
            Toggle("Longer Pause Between Letters", isOn: Binding(
                get: { viewModel.isLongerPauseEnabled },
                set: { _ in viewModel.toggleLongerPause() }
            ))
            
            Toggle("Announce Letters Count", isOn: Binding(
                get: { viewModel.isAnnounceLettersCountEnabled },
                set: { _ in viewModel.toggleAnnounceLettersCount() }
            ))
        }
    }
    
    // MARK: - Prediction Section
    
    private var predictionSection: some View {
        Section("Word Prediction") {
            Picker("Engine", selection: Binding(
                get: { viewModel.currentPredictionEngine },
                set: { viewModel.updatePredictionEngine($0) }
            )) {
                ForEach(viewModel.availableEngines, id: \.self) { engine in
                    Text(engine.displayName)
                        .tag(engine)
                }
            }
            .pickerStyle(.menu)
            
            HStack {
                Text("Performance")
                    .foregroundColor(.secondary)
                Spacer()
                Text(viewModel.engineMetrics)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Cloud Section
    
    private var cloudSection: some View {
        Section("Cloud Sync") {
            Toggle("Enable Cloud Sync", isOn: Binding(
                get: { viewModel.isCloudSyncEnabled },
                set: { _ in viewModel.toggleCloudSync() }
            ))
            
            if viewModel.isCloudSyncEnabled {
                Text("Your settings and custom words will be synced across devices using iCloud.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - About Section
    
    private var aboutSection: some View {
        Section("About") {
            NavigationLink("About SwipeSpeak") {
                AboutView()
            }
            
            NavigationLink("Acknowledgements") {
                AcknowledgementsView()
            }
            
            Button("Reset to Defaults") {
                viewModel.resetToDefaults()
            }
            .foregroundColor(.red)
        }
    }
}

// MARK: - Supporting Views

struct KeyboardSettingsView: View {
    var body: some View {
        Text("Keyboard Settings")
            .navigationTitle("Keyboard")
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct VoiceSelectionView: View {
    @StateObject private var viewModel = SettingsViewModel()
    
    var body: some View {
        List {
            if viewModel.isLoadingVoices {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading voices...")
                        .foregroundColor(.secondary)
                }
                .padding()
            } else {
                ForEach(viewModel.availableVoices, id: \.identifier) { voice in
                    VoiceRow(
                        voice: voice,
                        isSelected: voice.identifier == viewModel.currentVoice?.identifier
                    ) {
                        viewModel.updateVoice(voice)
                    }
                }
            }
        }
        .navigationTitle("Voice Selection")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct VoiceRow: View {
    let voice: AVSpeechSynthesisVoice
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading) {
                    Text(voice.name)
                        .foregroundColor(.primary)
                    Text(voice.language)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AboutView: View {
    @State private var showingContactOptions = false

    var body: some View {
        List {
            Section {
                Button("Contact Support") {
                    showingContactOptions = true
                }
                .foregroundColor(.blue)
            }

            Section {
                VStack(alignment: .leading, spacing: 16) {
                    Text("SwipeSpeak")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("An innovative communication app designed to help users express themselves through intuitive swipe gestures and word prediction.")
                        .font(.body)

                    Text("Developed by Team Gleason")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text("Version \(appVersion) (\(appBuild))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Choose an email app:", isPresented: $showingContactOptions) {
            ContactOptionsView()
        }
    }
}

struct ContactOptionsView: View {
    let email = "swipespeak@teamgleason.org"
    let subject = "SwipeSpeak Feedback"

    var body: some View {
        let urls = [
            ("Mail", "mailto:\(email)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "Feedback")"),
            ("Gmail", "googlegmail:///co?to=\(email)&subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "Feedback")"),
            ("Inbox", "inbox-gmail://co?to=\(email)&subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "Feedback")"),
            ("Outlook", "ms-outlook://compose?to=\(email)&subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "Feedback")")
        ]

        ForEach(urls, id: \.0) { name, urlString in
            if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
                Button(name) {
                    UIApplication.shared.open(url)
                }
            }
        }

        Button("Cancel", role: .cancel) { }
    }
}

struct AcknowledgementsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Third-Party Libraries")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("MarkdownView")
                        .fontWeight(.semibold)
                    Text("Used for rendering markdown content")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Zephyr")
                        .fontWeight(.semibold)
                    Text("Used for iCloud synchronization")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("DZNEmptyDataSet")
                        .fontWeight(.semibold)
                    Text("Used for empty state management")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
        .navigationTitle("Acknowledgements")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
}
