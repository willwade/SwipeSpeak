//
//  MainViewModel.swift
//  SwipeSpeak
//
//  Created by SwiftUI Migration on 22/06/2025.
//  Copyright © 2025 TeamGleason. All rights reserved.
//

import SwiftUI
import Combine
import AVFoundation

/// Main view model that orchestrates the core SwipeSpeak functionality
/// Replaces the business logic from MainTVC while maintaining all existing functionality
@MainActor
class MainViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var currentSentence: String = ""
    @Published var currentWord: String = ""
    @Published var enteredKeys: [Int] = []
    @Published var predictions: [String] = Array(repeating: "", count: 6)
    @Published var isWordHighlighted: Bool = false
    @Published var highlightedPredictionIndex: Int? = nil
    @Published var showingSettings: Bool = false
    @Published var showingHistory: Bool = false
    
    // MARK: - Dependencies

    // TODO: Re-enable full prediction engine once concurrency issues are resolved
    // For now, use simplified prediction logic
    private let speechSynthesizer = SpeechSynthesizer.shared
    private let userPreferences = UserPreferences.shared
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    private var buildWordPauseSeconds: Double = 2.0
    private var viewDidAppear = false
    
    // MARK: - Child ViewModels
    
    @Published var textDisplayViewModel: TextDisplayViewModel
    @Published var keyboardViewModel: KeyboardViewModel
    
    // MARK: - Initialization
    
    init() {
        // Initialize child view models
        self.textDisplayViewModel = TextDisplayViewModel()
        self.keyboardViewModel = KeyboardViewModel()
        
        // Setup initial state
        setupInitialState()
        setupBindings()
        setupCallbacks()
    }
    
    // MARK: - Setup Methods
    
    private func setupInitialState() {
        buildWordPauseSeconds = userPreferences.longerPauseBetweenLetters ? 3.5 : 2.0
        
        // Initialize text display
        textDisplayViewModel.setSentenceText("")
        textDisplayViewModel.setWordText("")
        
        // Initialize keyboard
        keyboardViewModel.keyboardLayout = userPreferences.keyboardLayout
        
        // Setup word prediction engine
        setupWordPredictionEngine()
    }
    
    private func setupBindings() {
        // Observe keyboard changes
        keyboardViewModel.$enteredKeys
            .receive(on: DispatchQueue.main)
            .sink { [weak self] keys in
                self?.enteredKeys = keys
                self?.updatePredictions()
                self?.updateCurrentWordDisplay()
            }
            .store(in: &cancellables)
        
        // Observe user preferences changes
        userPreferences.$keyboardLayout
            .receive(on: DispatchQueue.main)
            .sink { [weak self] layout in
                self?.keyboardViewModel.keyboardLayout = layout
                self?.setupWordPredictionEngine() // Re-setup prediction engine with new layout
            }
            .store(in: &cancellables)
        
        // Observe sentence and word changes
        $currentSentence
            .receive(on: DispatchQueue.main)
            .sink { [weak self] sentence in
                self?.textDisplayViewModel.setSentenceText(sentence)
            }
            .store(in: &cancellables)
        
        $currentWord
            .receive(on: DispatchQueue.main)
            .sink { [weak self] word in
                self?.textDisplayViewModel.setWordText(word)
            }
            .store(in: &cancellables)
        
        $predictions
            .receive(on: DispatchQueue.main)
            .sink { [weak self] predictions in
                self?.textDisplayViewModel.updatePredictions(predictions)
                let predictionsWithFreq = predictions.enumerated().map { ($0.element, 100 - $0.offset) }
                self?.keyboardViewModel.updatePredictions(predictionsWithFreq)
            }
            .store(in: &cancellables)
    }
    
    private func setupCallbacks() {
        // Text display callbacks
        textDisplayViewModel.onSentenceTapped = { [weak self] in
            self?.sentenceTapped()
        }
        
        textDisplayViewModel.onSentenceLongPressed = { [weak self] in
            self?.sentenceLongPressed()
        }
        
        textDisplayViewModel.onPredictionSelected = { [weak self] prediction, index in
            _ = self?.addWordToSentence(word: prediction, announce: true)
        }
        
        textDisplayViewModel.onPredictionLongPressed = { [weak self] prediction, index in
            _ = self?.addWordToSentence(word: prediction, announce: false)
        }
        
        textDisplayViewModel.onAnnounce = { [weak self] text in
            self?.announce(text)
        }
        
        // Keyboard callbacks
        keyboardViewModel.onWordCompleted = { [weak self] word in
            _ = self?.addWordToSentence(word: word, announce: true)
        }
        
        keyboardViewModel.onLetterAdded = { [weak self] letter in
            self?.updateCurrentWordDisplay()
        }
        
        keyboardViewModel.onBackspace = { [weak self] in
            self?.backspace(noSound: true)
        }
        
        keyboardViewModel.onPredictionSelected = { [weak self] prediction in
            _ = self?.addWordToSentence(word: prediction, announce: true)
        }
    }
    
    // MARK: - Public Methods

    func onViewDidAppear() {
        guard !viewDidAppear else { return }
        viewDidAppear = true

        // Update predictions for initial state
        updatePredictions()
    }
    
    func presentSettings() {
        showingSettings = true
    }
    
    func presentHistory() {
        showingHistory = true
    }
    
    // MARK: - Core Business Logic (from MainTVC)
    
    private func setupWordPredictionEngine() {
        // TODO: Re-enable full prediction engine once PredictionEngine.swift is properly included in Xcode project
        // For now, using simplified prediction logic with proper key mapping
    }
    
    func updatePredictions() {
        guard !enteredKeys.isEmpty else {
            // Clear predictions when no keys entered
            predictions = Array(repeating: "", count: 6)
            return
        }

        // TODO: Re-enable full prediction engine once PredictionEngine.swift is properly included in Xcode project
        // For now, use simplified prediction logic with proper key mapping
        let newPredictions = getSimplePredictions(for: enteredKeys)

        // Ensure we have exactly 6 predictions (pad with empty strings if needed)
        var paddedPredictions = Array(newPredictions.prefix(6))
        while paddedPredictions.count < 6 {
            paddedPredictions.append("")
        }

        predictions = paddedPredictions
    }
    
    func updateCurrentWordDisplay() {
        if enteredKeys.isEmpty {
            currentWord = ""
            isWordHighlighted = false
        } else {
            // Build current word from entered keys using keyboard layout
            let letters = enteredKeys.compactMap { keyIndex in
                letter(from: keyIndex, layout: keyboardViewModel.keyboardLayout)
            }
            currentWord = letters.joined()
            isWordHighlighted = !currentWord.isEmpty
        }
    }
    
    @discardableResult
    func addWordToSentence(word: String, announce: Bool) -> Bool {
        guard !word.isEmpty else { return false }

        // Add word to sentence
        if currentSentence.isEmpty {
            currentSentence = word
        } else {
            currentSentence += " " + word
        }

        // Clear current word and entered keys
        currentWord = ""
        enteredKeys = []
        isWordHighlighted = false

        // Update keyboard state
        keyboardViewModel.enteredKeys.removeAll()

        // Clear predictions
        predictions = Array(repeating: "", count: 6)

        // Add to user's sentence history
        userPreferences.addSentence(currentSentence)

        // Announce if requested
        if announce {
            self.announce(word)
        }

        return true
    }
    
    func backspace(noSound: Bool = false) {
        print("🔍 MainViewModel: backspace called")
        
        if !enteredKeys.isEmpty {
            // Remove last entered key
            enteredKeys.removeLast()
            keyboardViewModel.enteredKeys.removeLast()
            updateCurrentWordDisplay()
            updatePredictions()
        } else if !currentSentence.isEmpty {
            // Remove last word from sentence
            let words = currentSentence.components(separatedBy: " ")
            if words.count > 1 {
                currentSentence = words.dropLast().joined(separator: " ")
            } else {
                currentSentence = ""
            }
        }
        
        // Play sound if not suppressed
        if !noSound && userPreferences.audioFeedback {
            // Play backspace sound (implement sound playing)
        }
        
        // Vibrate if enabled
        if userPreferences.vibrate {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }
    }
    
    func announce(_ text: String) {
        print("🔍 MainViewModel: announce called with text: '\(text)'")
        speechSynthesizer.speak(text)
    }
    
    // MARK: - UI Event Handlers
    
    private func sentenceTapped() {
        print("🔍 MainViewModel: sentenceTapped called")
        
        if !currentSentence.isEmpty {
            announce(currentSentence)
        }
    }
    
    private func sentenceLongPressed() {
        print("🔍 MainViewModel: sentenceLongPressed called")
        
        if !currentSentence.isEmpty {
            // Speak sentence and clear it
            announce(currentSentence)
            currentSentence = ""
            
            // Also clear current word
            currentWord = ""
            enteredKeys = []
            isWordHighlighted = false
            keyboardViewModel.enteredKeys.removeAll()
            
            // Clear predictions
            predictions = Array(repeating: "", count: 6)
        }
    }

    // MARK: - Helper Methods

    /// Get the key letter grouping for a specific keyboard layout
    private func getKeyLetterGrouping(for layout: KeyboardLayout) -> [String] {
        switch layout {
        case .keys4:
            return Constants.keyLetterGrouping4Keys
        case .keys6:
            return Constants.keyLetterGrouping6Keys
        case .keys8:
            return Constants.keyLetterGrouping8Keys
        case .strokes2:
            return Constants.keyLetterGroupingSteve
        case .msr:
            return Constants.keyLetterGroupingMSR
        }
    }

    /// Convert a key index to a letter based on the keyboard layout
    private func letter(from keyIndex: Int, layout: KeyboardLayout) -> String? {
        let grouping = getKeyLetterGrouping(for: layout)

        // For regular keyboards, return the first letter of the group for display
        guard keyIndex >= 0 && keyIndex < grouping.count else { return nil }
        let letterGroup = grouping[keyIndex]
        return letterGroup.isEmpty ? nil : String(letterGroup.first!)
    }

    /// Simplified prediction logic for Phase 3
    /// TODO: Replace with full prediction engine once concurrency issues are resolved
    private func getSimplePredictions(for keys: [Int]) -> [String] {
        guard !keys.isEmpty else {
            return ["the", "and", "to", "of", "a", "in"] // Common words when no input
        }

        // Convert keys to letters based on current keyboard layout
        let letters = keys.compactMap { letter(from: $0, layout: keyboardViewModel.keyboardLayout) }
        let currentInput = letters.joined().lowercased()

        // Simple prediction based on common English words that start with the input
        let commonWords = [
            "the", "and", "to", "of", "a", "in", "is", "it", "you", "that",
            "he", "was", "for", "on", "are", "as", "with", "his", "they", "i",
            "at", "be", "this", "have", "from", "or", "one", "had", "by", "word",
            "but", "not", "what", "all", "were", "we", "when", "your", "can", "said",
            "there", "each", "which", "she", "do", "how", "their", "if", "will", "up",
            "other", "about", "out", "many", "then", "them", "these", "so", "some", "her",
            "would", "make", "like", "into", "him", "has", "two", "more", "go", "no",
            "way", "could", "my", "than", "first", "water", "been", "call", "who", "its"
        ]

        // Filter words that start with current input
        let matchingWords = commonWords.filter { $0.hasPrefix(currentInput) }

        // If we have matches, return them, otherwise return some common words
        if !matchingWords.isEmpty {
            return Array(matchingWords.prefix(6))
        } else {
            // Return words that contain any of the input letters
            let containingWords = commonWords.filter { word in
                currentInput.allSatisfy { letter in word.contains(letter) }
            }
            return Array(containingWords.prefix(6))
        }
    }
}
