//
//  KeyboardViewModel.swift
//  SwipeSpeak
//
//  Created by SwiftUI Migration on 20/01/2025.
//  Copyright © 2025 TeamGleason. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

/// ViewModel for managing keyboard interface logic and state
@MainActor
class KeyboardViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Current word being typed
    @Published var currentWord: String = ""
    
    /// Current sentence being built
    @Published var currentSentence: String = ""
    
    /// List of prediction suggestions
    @Published var predictions: [(String, Int)] = []
    
    /// Currently entered key sequence
    @Published var enteredKeys: [Int] = []
    
    /// Current keyboard layout
    @Published var keyboardLayout: KeyboardLayout = .default
    
    /// Whether the keyboard is in two-strokes mode
    @Published var isTwoStrokesMode: Bool = false
    
    /// Current keyboard indicator state
    @Published var keyboardIndicator: String = ""
    
    /// Loading state for predictions
    @Published var isLoadingPredictions: Bool = false

    /// First stroke in two-stroke mode
    @Published var firstStroke: Int? = nil

    /// Current MSR keyboard state
    @Published var msrKeyboardState: MSRKeyboardState = .master

    // MARK: - Dependencies
    
    private let predictionManager: PredictionEngineManager
    private let userPreferences: UserPreferences
    private let speechSynthesizer: SpeechSynthesizer
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(
        predictionManager: PredictionEngineManager = PredictionEngineManager.shared,
        userPreferences: UserPreferences = UserPreferences.shared,
        speechSynthesizer: SpeechSynthesizer = SpeechSynthesizer.shared
    ) {
        self.predictionManager = predictionManager
        self.userPreferences = userPreferences
        self.speechSynthesizer = speechSynthesizer
        
        setupBindings()
    }
    
    // MARK: - Setup
    
    private func setupBindings() {
        // Bind to user preferences changes
        userPreferences.$keyboardLayout
            .receive(on: DispatchQueue.main)
            .assign(to: \.keyboardLayout, on: self)
            .store(in: &cancellables)
        
        // Update two-strokes mode based on keyboard layout
        $keyboardLayout
            .map { layout in
                layout == .strokes2 || layout == .msr
            }
            .assign(to: \.isTwoStrokesMode, on: self)
            .store(in: &cancellables)
        
        // Update predictions when keys change
        $enteredKeys
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .sink { [weak self] keys in
                Task {
                    await self?.updatePredictions(for: keys)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// Handle key entry
    func keyEntered(_ key: Int, isSwipe: Bool) {
        enteredKeys.append(key)
        updateKeyboardIndicator(for: key)
        
        // Play audio feedback
        if isSwipe {
            playSoundSwipe()
        } else {
            playSoundClick()
        }
        
        // Vibrate if enabled
        if userPreferences.vibrate {
            vibrate()
        }
    }
    
    /// Handle first stroke in two-strokes mode
    func firstStrokeEntered(key: Int, isSwipe: Bool) {
        firstStroke = key
        updateKeyboardIndicator(for: key)

        // Add arrow to current word for visual feedback
        if let arrow = Constants.arrows2StrokesMap[key] {
            currentWord += arrow
        }

        // Play audio feedback
        if isSwipe {
            playSoundSwipe()
        } else {
            playSoundClick()
        }
    }
    
    /// Handle second stroke in two-strokes mode
    func secondStrokeEntered(key: Int, isSwipe: Bool) {
        enteredKeys.append(key)
        updateKeyboardIndicator(for: key)

        // Reset first stroke
        firstStroke = nil

        // Play audio feedback
        if isSwipe {
            playSoundSwipe()
        } else {
            playSoundClick()
        }
    }

    /// Handle MSR keyboard key entry
    func msrKeyEntered(key: Int, isSwipe: Bool) {
        // MSR keyboard logic - will be implemented based on current state
        // For now, delegate to regular key entry
        keyEntered(key, isSwipe: isSwipe)
    }
    
    /// Select a prediction
    func selectPrediction(_ word: String) {
        currentWord = word
        enteredKeys.removeAll()
        predictions.removeAll()
        
        playSoundWordAdded()
    }
    
    /// Add current word to sentence
    func addWordToSentence() {
        guard !currentWord.isEmpty else { return }
        
        if currentSentence.isEmpty {
            currentSentence = currentWord
        } else {
            currentSentence += " " + currentWord
        }
        
        currentWord = ""
        enteredKeys.removeAll()
        predictions.removeAll()
        
        playSoundWordAdded()
    }
    
    /// Speak current sentence
    func speakSentence() async {
        guard !currentSentence.isEmpty else { return }

        _ = await speechSynthesizer.speakAsync(currentSentence)
    }
    
    /// Clear current word
    func clearWord() {
        currentWord = ""
        enteredKeys.removeAll()
        predictions.removeAll()
        
        playSoundBackspace()
    }
    
    /// Clear current sentence
    func clearSentence() {
        currentSentence = ""
        currentWord = ""
        enteredKeys.removeAll()
        predictions.removeAll()
        
        playSoundBackspace()
    }
    
    /// Backspace last character or key
    func backspace() {
        if !currentWord.isEmpty {
            currentWord.removeLast()
        } else if !enteredKeys.isEmpty {
            enteredKeys.removeLast()
            Task {
                await updatePredictions(for: enteredKeys)
            }
        }
        
        playSoundBackspace()
    }
    
    // MARK: - Private Methods
    
    private func updatePredictions(for keys: [Int]) async {
        guard !keys.isEmpty else {
            predictions = []
            return
        }

        isLoadingPredictions = true

        // Use the synchronous method for now, wrapped in Task for async context
        let suggestions = await Task {
            return predictionManager.suggestions(for: keys)
        }.value

        await MainActor.run {
            self.predictions = suggestions
            self.isLoadingPredictions = false
        }
    }
    
    private func updateKeyboardIndicator(for key: Int) {
        // Update keyboard indicator based on key
        keyboardIndicator = "Key \(key)"
    }
}

// MARK: - Audio Feedback

extension KeyboardViewModel {
    private func playSoundClick() {
        if userPreferences.audioFeedback {
            SwipeSpeak.playSoundClick()
        }
    }

    private func playSoundSwipe() {
        if userPreferences.audioFeedback {
            SwipeSpeak.playSoundSwipe()
        }
    }

    private func playSoundBackspace() {
        if userPreferences.audioFeedback {
            SwipeSpeak.playSoundBackspace()
        }
    }

    private func playSoundWordAdded() {
        if userPreferences.audioFeedback {
            SwipeSpeak.playSoundWordAdded()
        }
    }

    private func vibrate() {
        SwipeSpeak.vibrate()
    }
}
