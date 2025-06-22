//
//  SettingsViewModel.swift
//  SwipeSpeak
//
//  Created by SwiftUI Migration on 20/01/2025.
//  Copyright © 2025 TeamGleason. All rights reserved.
//

import Foundation
import Combine
import SwiftUI
import AVFoundation

/// ViewModel for managing settings and configuration
@MainActor
class SettingsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Available keyboard layouts
    @Published var availableLayouts: [KeyboardLayout] = [.keys4, .keys6, .keys8, .strokes2, .msr]
    
    /// Available voices for speech synthesis
    @Published var availableVoices: [AVSpeechSynthesisVoice] = []
    
    /// Available prediction engines
    @Published var availableEngines: [String] = ["custom", "native"] // Temporarily simplified
    
    /// Current prediction engine performance metrics
    @Published var engineMetrics: String = "Metrics not available"
    
    /// Loading state for voice loading
    @Published var isLoadingVoices: Bool = false

    /// Error state for settings operations
    @Published var errorMessage: String?

    // MARK: - Dependencies

    private let userPreferences: UserPreferences
    // private let predictionManager: PredictionEngineManager // Temporarily commented out

    // MARK: - Private Properties

    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(
        userPreferences: UserPreferences = UserPreferences.shared
        // predictionManager: PredictionEngineManager = PredictionEngineManager.shared // Temporarily commented out
    ) {
        self.userPreferences = userPreferences
        // self.predictionManager = predictionManager // Temporarily commented out

        setupBindings()
        loadAvailableVoices()
        loadEngineMetrics()
    }
    
    // MARK: - Setup

    private func setupBindings() {
        // Monitor prediction engine changes - Note: predictionEngineType is not @Published yet
        // This will be updated when we fully migrate UserPreferences
        // For now, we'll manually call loadEngineMetrics when needed
    }
    
    // MARK: - Public Methods
    
    /// Update keyboard layout
    func updateKeyboardLayout(_ layout: KeyboardLayout) {
        userPreferences.keyboardLayout = layout
    }
    
    /// Update speech rate
    func updateSpeechRate(_ rate: Float) {
        userPreferences.speechRate = rate
    }
    
    /// Update speech volume
    func updateSpeechVolume(_ volume: Float) {
        userPreferences.speechVolume = volume
    }
    
    /// Update voice selection
    func updateVoice(_ voice: AVSpeechSynthesisVoice) {
        userPreferences.voiceIdentifier = voice.identifier
    }
    
    /// Update prediction engine
    func updatePredictionEngine(_ engineType: String) {
        userPreferences.predictionEngineType = engineType
        // Note: switchEngine method will be added to PredictionEngineManager later
        // predictionManager.switchEngine(to: engineType)
        loadEngineMetrics()
    }
    
    /// Toggle audio feedback
    func toggleAudioFeedback() {
        userPreferences.audioFeedback.toggle()
    }
    
    /// Toggle vibration
    func toggleVibration() {
        userPreferences.vibrate.toggle()
    }
    
    /// Toggle longer pause between letters
    func toggleLongerPause() {
        userPreferences.longerPauseBetweenLetters.toggle()
    }
    
    /// Toggle announce letters count
    func toggleAnnounceLettersCount() {
        userPreferences.announceLettersCount.toggle()
    }
    
    /// Toggle cloud sync
    func toggleCloudSync() {
        userPreferences.enableCloudSync.toggle()
    }
    
    /// Test speech with current settings
    func testSpeech() async {
        let testText = "This is a test of the speech synthesis settings."
        _ = await SpeechSynthesizer.shared.speakAsync(testText)
    }
    
    /// Reset all settings to defaults
    func resetToDefaults() {
        userPreferences.resetToDefaults()
        loadEngineMetrics()
    }
    
    /// Export settings for backup
    func exportSettings() -> [String: Any] {
        return userPreferences.exportSettings()
    }
    
    /// Import settings from backup
    func importSettings(_ settings: [String: Any]) {
        do {
            try userPreferences.importSettings(settings)
            loadEngineMetrics()
            errorMessage = nil
        } catch {
            errorMessage = "Failed to import settings: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Private Methods
    
    private func loadAvailableVoices() {
        isLoadingVoices = true
        
        Task {
            let voices = AVSpeechSynthesisVoice.speechVoices()
                .filter { $0.language.hasPrefix("en") }
                .sorted { $0.name < $1.name }
            
            await MainActor.run {
                self.availableVoices = voices
                self.isLoadingVoices = false
            }
        }
    }
    
    private func loadEngineMetrics() {
        // Note: performanceMetrics will be available when we implement the full protocol
        // For now, create a placeholder
        engineMetrics = "Engine: \(currentPredictionEngine) - Ready"
    }
}

// MARK: - Computed Properties

extension SettingsViewModel {
    
    /// Current keyboard layout from preferences
    var currentKeyboardLayout: KeyboardLayout {
        userPreferences.keyboardLayout
    }
    
    /// Current speech rate from preferences
    var currentSpeechRate: Float {
        userPreferences.speechRate
    }
    
    /// Current speech volume from preferences
    var currentSpeechVolume: Float {
        userPreferences.speechVolume
    }
    
    /// Current voice from preferences
    var currentVoice: AVSpeechSynthesisVoice? {
        guard let identifier = userPreferences.voiceIdentifier else { return nil }
        return AVSpeechSynthesisVoice(identifier: identifier)
    }
    
    /// Current prediction engine type
    var currentPredictionEngine: String {
        userPreferences.predictionEngineType ?? "custom"
    }
    
    /// Audio feedback enabled state
    var isAudioFeedbackEnabled: Bool {
        userPreferences.audioFeedback
    }
    
    /// Vibration enabled state
    var isVibrationEnabled: Bool {
        userPreferences.vibrate
    }
    
    /// Longer pause enabled state
    var isLongerPauseEnabled: Bool {
        userPreferences.longerPauseBetweenLetters
    }
    
    /// Announce letters count enabled state
    var isAnnounceLettersCountEnabled: Bool {
        userPreferences.announceLettersCount
    }
    
    /// Cloud sync enabled state
    var isCloudSyncEnabled: Bool {
        userPreferences.enableCloudSync
    }
}

// MARK: - Helper Extensions

extension UserPreferences {
    
    /// Reset all preferences to default values
    func resetToDefaults() {
        keyboardLayout = .default
        speechRate = AVSpeechUtteranceDefaultSpeechRate
        speechVolume = 1.0
        audioFeedback = true
        vibrate = false
        longerPauseBetweenLetters = true
        announceLettersCount = true
        enableCloudSync = true
        predictionEngineType = "custom"
        voiceIdentifier = nil
    }
    
    /// Export current settings
    func exportSettings() -> [String: Any] {
        return [
            "keyboardLayout": keyboardLayout.rawValue,
            "speechRate": speechRate,
            "speechVolume": speechVolume,
            "audioFeedback": audioFeedback,
            "vibrate": vibrate,
            "longerPauseBetweenLetters": longerPauseBetweenLetters,
            "announceLettersCount": announceLettersCount,
            "enableCloudSync": enableCloudSync,
            "predictionEngineType": predictionEngineType ?? "custom",
            "voiceIdentifier": voiceIdentifier as Any
        ]
    }
    
    /// Import settings from dictionary
    func importSettings(_ settings: [String: Any]) throws {
        if let layoutRaw = settings["keyboardLayout"] as? Int,
           let layout = KeyboardLayout(rawValue: layoutRaw) {
            keyboardLayout = layout
        }
        
        if let rate = settings["speechRate"] as? Float {
            speechRate = rate
        }
        
        if let volume = settings["speechVolume"] as? Float {
            speechVolume = volume
        }
        
        if let feedback = settings["audioFeedback"] as? Bool {
            audioFeedback = feedback
        }
        
        if let vibrate = settings["vibrate"] as? Bool {
            self.vibrate = vibrate
        }
        
        if let pause = settings["longerPauseBetweenLetters"] as? Bool {
            longerPauseBetweenLetters = pause
        }
        
        if let announce = settings["announceLettersCount"] as? Bool {
            announceLettersCount = announce
        }
        
        if let sync = settings["enableCloudSync"] as? Bool {
            enableCloudSync = sync
        }
        
        if let engine = settings["predictionEngineType"] as? String {
            predictionEngineType = engine
        }
        
        if let voice = settings["voiceIdentifier"] as? String {
            voiceIdentifier = voice
        }
    }
}
