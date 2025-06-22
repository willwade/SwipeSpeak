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

    // MARK: - Callback Properties for MainTVC Integration

    /// Called when a word is completed and should be added to the text display
    var onWordCompleted: ((String) -> Void)?

    /// Called when a letter is added to the current word
    var onLetterAdded: ((String) -> Void)?

    /// Called when backspace should be performed
    var onBackspace: (() -> Void)?

    /// Called when space should be added
    var onSpace: (() -> Void)?

    /// Called when a prediction is selected
    var onPredictionSelected: ((String) -> Void)?

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
        
        // Note: Predictions are now handled by MainTVC, not KeyboardViewModel
        // This simplifies the architecture and avoids duplication
    }
    
    // MARK: - Public Methods
    
    /// Handle key entry
    func keyEntered(_ key: Int, isSwipe: Bool) {
        print("🔍 KeyboardViewModel: keyEntered called - key: \(key), isSwipe: \(isSwipe)")
        enteredKeys.append(key)
        print("🔍 KeyboardViewModel: enteredKeys now: \(enteredKeys)")
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

        // Notify MainTVC
        onPredictionSelected?(word)
    }
    
    /// Add current word to sentence
    func addWordToSentence() {
        guard !currentWord.isEmpty else { return }

        let wordToAdd = currentWord

        if currentSentence.isEmpty {
            currentSentence = currentWord
        } else {
            currentSentence += " " + currentWord
        }

        currentWord = ""
        enteredKeys.removeAll()
        predictions.removeAll()

        playSoundWordAdded()

        // Notify MainTVC
        onWordCompleted?(wordToAdd)
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

        // Notify MainTVC
        onBackspace?()
    }

    /// Add space - completes current word and adds space
    func addSpace() {
        if !currentWord.isEmpty {
            addWordToSentence()
        }

        // Notify MainTVC
        onSpace?()
    }

    /// Update current word from MainTVC (used instead of internal prediction system)
    func updateCurrentWord(_ word: String) {
        print("🔍 KeyboardViewModel: updateCurrentWord called with: '\(word)'")
        currentWord = word
    }

    /// Update predictions from MainTVC (used instead of internal prediction system)
    func updatePredictions(_ newPredictions: [(String, Int)]) {
        print("🔍 KeyboardViewModel: updatePredictions called with \(newPredictions.count) predictions")
        predictions = newPredictions
    }
    
    // MARK: - Private Methods
    
    private func updatePredictions(for keys: [Int]) async {
        print("🔍 KeyboardViewModel: updatePredictions called for keys: \(keys)")
        guard !keys.isEmpty else {
            predictions = []
            currentWord = ""
            print("🔍 KeyboardViewModel: No keys, cleared predictions and currentWord")
            return
        }

        isLoadingPredictions = true

        // Use the synchronous method for now, wrapped in Task for async context
        let suggestions = await Task {
            print("🔍 KeyboardViewModel: Calling predictionManager.suggestions for keys: \(keys)")
            let results = predictionManager.suggestions(for: keys)
            print("🔍 KeyboardViewModel: Got \(results.count) suggestions: \(results.prefix(3))")
            return results
        }.value

        await MainActor.run {
            self.predictions = suggestions
            self.isLoadingPredictions = false

            // Update currentWord with the first prediction (trimmed to match entered keys)
            if let firstPrediction = suggestions.first {
                let trimmedWord = String(firstPrediction.0.prefix(keys.count))
                self.currentWord = trimmedWord
                print("🔍 KeyboardViewModel: Updated currentWord to: '\(trimmedWord)' from prediction: '\(firstPrediction.0)'")
            } else {
                self.currentWord = ""
                print("🔍 KeyboardViewModel: No predictions found, cleared currentWord")
            }
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
