//
//  TextDisplayViewModel.swift
//  SwipeSpeak
//
//  Created by SwiftUI Migration on 2025-01-20.
//  Copyright © 2025 TeamGleason. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

/// ViewModel for managing text display state and interactions
@MainActor
class TextDisplayViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var sentenceText: String = ""
    @Published var wordText: String = ""
    @Published var predictions: [String] = Array(repeating: "", count: 6)
    @Published var isWordHighlighted: Bool = false
    @Published var highlightedPredictionIndex: Int? = nil
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    private let predictionEngineManager = PredictionEngineManager.shared
    
    // Callbacks to MainTVC for actions that require UIKit integration
    var onSentenceTapped: (() -> Void)?
    var onSentenceLongPressed: (() -> Void)?
    var onWordTapped: (() -> Void)?
    var onWordLongPressed: (() -> Void)?
    var onPredictionSelected: ((String, Int) -> Void)?
    var onPredictionLongPressed: ((String, Int) -> Void)?
    var onAnnounce: ((String) -> Void)?
    
    // MARK: - Initialization
    
    init() {
        setupBindings()
    }
    
    // MARK: - Public Methods
    
    /// Update sentence text with accessibility support
    func setSentenceText(_ text: String) {
        sentenceText = text
    }
    
    /// Update word text with accessibility support
    func setWordText(_ text: String) {
        wordText = text
    }
    
    /// Update predictions array
    func updatePredictions(_ newPredictions: [String]) {
        // Ensure we always have exactly 6 elements
        var updatedPredictions = Array(repeating: "", count: 6)
        for (index, prediction) in newPredictions.prefix(6).enumerated() {
            updatedPredictions[index] = prediction
        }
        predictions = updatedPredictions
    }
    
    /// Clear all text displays
    func clearAll() {
        sentenceText = ""
        wordText = ""
        predictions = Array(repeating: "", count: 6)
        isWordHighlighted = false
        highlightedPredictionIndex = nil
    }
    
    /// Highlight word display
    func highlightWord(_ highlight: Bool = true) {
        isWordHighlighted = highlight
    }
    
    /// Highlight specific prediction
    func highlightPrediction(at index: Int?) {
        highlightedPredictionIndex = index
    }
    
    /// Remove all highlights
    func removeAllHighlights() {
        isWordHighlighted = false
        highlightedPredictionIndex = nil
    }
    
    // MARK: - User Interaction Handlers
    
    func sentenceTapped() {
        guard !sentenceText.isEmpty else { return }
        onAnnounce?(sentenceText)
        onSentenceTapped?()
    }
    
    func sentenceLongPressed() {
        onSentenceLongPressed?()
    }
    
    func wordTapped() {
        guard !wordText.isEmpty, !wordText.containsArrow() else { return }
        
        if isWordHighlighted {
            // Word is already highlighted, add to sentence
            onPredictionSelected?(wordText, -1) // -1 indicates word label
        } else {
            // Highlight the word and announce it
            highlightWord(true)
            onAnnounce?(wordText)
        }
    }
    
    func wordLongPressed() {
        guard !wordText.isEmpty, !wordText.containsArrow() else { return }
        onPredictionLongPressed?(wordText, -1) // -1 indicates word label
    }
    
    func predictionTapped(at index: Int) {
        guard index < predictions.count, !predictions[index].isEmpty else { return }
        
        let prediction = predictions[index]
        
        if highlightedPredictionIndex == index {
            // Prediction is already highlighted, add to sentence
            onPredictionSelected?(prediction, index)
        } else {
            // Highlight the prediction and announce it
            removeAllHighlights()
            highlightPrediction(at: index)
            onAnnounce?(prediction)
        }
    }
    
    func predictionLongPressed(at index: Int) {
        guard index < predictions.count, !predictions[index].isEmpty else { return }
        onPredictionLongPressed?(predictions[index], index)
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // Listen for user preferences changes that might affect display
        NotificationCenter.default.publisher(for: .NSUserDefaultsDidChange)
            .sink { [weak self] _ in
                // Handle any preference changes that affect text display
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
}

// MARK: - Helper Extensions

extension String {
    func containsArrow() -> Bool {
        return self.contains("↑") || self.contains("↓") || self.contains("←") || self.contains("→")
    }
}

// MARK: - Integration Helper

/// Helper class to bridge between UIKit MainTVC and SwiftUI TextDisplayView
@MainActor
class TextDisplayBridge {
    
    private let viewModel: TextDisplayViewModel
    private weak var mainTVC: MainTVC?
    
    init(viewModel: TextDisplayViewModel, mainTVC: MainTVC) {
        self.viewModel = viewModel
        self.mainTVC = mainTVC
        setupCallbacks()
    }
    
    private func setupCallbacks() {
        viewModel.onSentenceTapped = { [weak self] in
            self?.mainTVC?.sentenceLabelTouched()
        }
        
        viewModel.onSentenceLongPressed = { [weak self] in
            self?.mainTVC?.sentenceLabelLongPressed()
        }
        
        viewModel.onWordTapped = { [weak self] in
            // Handle word tap - this would need to be implemented in MainTVC
            // For now, we'll use the existing label tap logic
        }
        
        viewModel.onWordLongPressed = { [weak self] in
            // Handle word long press
        }
        
        viewModel.onPredictionSelected = { [weak self] prediction, index in
            // Handle prediction selection - add to sentence
            self?.mainTVC?.addWordToSentence(word: prediction, announce: true)
        }
        
        viewModel.onPredictionLongPressed = { [weak self] prediction, index in
            // Handle prediction long press - add to sentence without announcement
            self?.mainTVC?.addWordToSentence(word: prediction, announce: false)
        }
        
        viewModel.onAnnounce = { [weak self] text in
            self?.mainTVC?.announce(text)
        }
    }
    
    // Methods to update the view model from MainTVC
    func updateSentenceText(_ text: String) {
        viewModel.setSentenceText(text)
    }
    
    func updateWordText(_ text: String) {
        viewModel.setWordText(text)
    }
    
    func updatePredictions(_ predictions: [String]) {
        viewModel.updatePredictions(predictions)
    }
    
    func highlightWord(_ highlight: Bool = true) {
        viewModel.highlightWord(highlight)
    }
    
    func highlightPrediction(at index: Int?) {
        viewModel.highlightPrediction(at: index)
    }
    
    func removeAllHighlights() {
        viewModel.removeAllHighlights()
    }
}
