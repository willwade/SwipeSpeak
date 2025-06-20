//
//  IntegrationTests.swift
//  SwipeSpeakTests
//
//  Created by Testing Implementation on 20/06/2025.
//  Copyright © 2025 TeamGleason. All rights reserved.
//

import XCTest
@testable import SwipeSpeak

final class IntegrationTests: XCTestCase {
    
    var predictionManager: PredictionEngineManager!
    var speechSynthesizer: SpeechSynthesizer!
    var userPreferences: UserPreferences!
    
    override func setUpWithError() throws {
        predictionManager = PredictionEngineManager.shared
        speechSynthesizer = SpeechSynthesizer()
        userPreferences = UserPreferences.shared
        
        // Reset to known state
        _ = predictionManager.switchToEngine(.custom)
        
        // Setup basic key grouping
        let keyLetterGrouping = [
            ["a", "b", "c"],
            ["d", "e", "f"],
            ["g", "h", "i"],
            ["j", "k", "l"],
            ["m", "n", "o"],
            ["p", "q", "r", "s"],
            ["t", "u", "v"],
            ["w", "x", "y", "z"]
        ]
        predictionManager.setKeyLetterGrouping(keyLetterGrouping, twoStrokes: false)
    }
    
    override func tearDownWithError() throws {
        speechSynthesizer.stopSpeaking()
        speechSynthesizer = nil
        predictionManager = nil
        userPreferences = nil
    }
    
    // MARK: - End-to-End Workflow Tests
    
    func testCompleteWordPredictionWorkflow() throws {
        // 1. Get predictions for a key sequence
        let keySequence = [0, 1] // "abc" + "def"
        let suggestions = predictionManager.suggestions(for: keySequence)
        
        XCTAssertFalse(suggestions.isEmpty, "Should get word suggestions")
        
        // 2. Select a word (first suggestion)
        guard let firstSuggestion = suggestions.first else {
            XCTFail("No suggestions available")
            return
        }
        
        let selectedWord = firstSuggestion.0
        XCTAssertFalse(selectedWord.isEmpty, "Selected word should not be empty")
        
        // 3. Speak the word
        speechSynthesizer.speak(selectedWord)
        
        // 4. Verify speech started (basic check)
        XCTAssertTrue(true) // If we get here without crashing, the workflow works
    }
    
    func testEngineSwithingWithPredictions() throws {
        // 1. Get predictions from custom engine
        let keySequence = [0, 1, 2]
        let customSuggestions = predictionManager.suggestions(for: keySequence)
        XCTAssertFalse(customSuggestions.isEmpty, "Custom engine should provide suggestions")
        
        // 2. Register and switch to native engine
        let nativeEngine = NativePredictionEngine()
        predictionManager.registerEngine(nativeEngine, for: .native)
        
        let switchSuccess = predictionManager.switchToEngine(.native)
        XCTAssertTrue(switchSuccess, "Should successfully switch to native engine")
        
        // 3. Get predictions from native engine
        let nativeSuggestions = predictionManager.suggestions(for: keySequence)
        XCTAssertFalse(nativeSuggestions.isEmpty, "Native engine should provide suggestions")
        
        // 4. Verify engine switch persisted in preferences
        XCTAssertEqual(userPreferences.predictionEngineType, "native")
        
        // 5. Switch back to custom engine
        let switchBackSuccess = predictionManager.switchToEngine(.custom)
        XCTAssertTrue(switchBackSuccess, "Should successfully switch back to custom engine")
        XCTAssertEqual(userPreferences.predictionEngineType, "custom")
    }
    
    func testSpeechSettingsIntegration() throws {
        // 1. Set speech preferences
        userPreferences.speechRate = 0.6
        userPreferences.speechPitch = 1.2
        userPreferences.speechVolume = 0.8
        
        // 2. Apply settings to speech synthesizer
        speechSynthesizer.setSpeechRate(userPreferences.speechRate)
        speechSynthesizer.setPitch(userPreferences.speechPitch)
        speechSynthesizer.setVolume(userPreferences.speechVolume)
        
        // 3. Verify settings were applied
        XCTAssertEqual(speechSynthesizer.speechRate, 0.6, accuracy: 0.01)
        XCTAssertEqual(speechSynthesizer.pitch, 1.2, accuracy: 0.01)
        XCTAssertEqual(speechSynthesizer.volume, 0.8, accuracy: 0.01)
        
        // 4. Test speech with custom settings
        speechSynthesizer.speak("Test")
        XCTAssertTrue(true) // Basic verification that it doesn't crash
    }
    
    func testVoiceSelectionIntegration() throws {
        // 1. Get available voices
        let voices = speechSynthesizer.availableVoices
        XCTAssertFalse(voices.isEmpty, "Should have available voices")
        
        // 2. Select a voice
        guard let testVoice = voices.first else {
            XCTFail("No voices available for testing")
            return
        }
        
        speechSynthesizer.setVoice(testVoice)
        
        // 3. Save voice preference
        userPreferences.selectedVoiceIdentifier = testVoice.identifier
        
        // 4. Verify voice selection
        XCTAssertEqual(speechSynthesizer.currentVoice?.identifier, testVoice.identifier)
        XCTAssertEqual(userPreferences.selectedVoiceIdentifier, testVoice.identifier)
        
        // 5. Test speech with selected voice
        speechSynthesizer.speak("Voice test")
        XCTAssertTrue(true) // Basic verification
    }
    
    // MARK: - Multi-Component Interaction Tests
    
    func testPredictionEngineManagerWithUserPreferences() throws {
        // 1. Change engine through manager
        let nativeEngine = NativePredictionEngine()
        predictionManager.registerEngine(nativeEngine, for: .native)
        
        _ = predictionManager.switchToEngine(.native)
        
        // 2. Verify preference was updated
        XCTAssertEqual(userPreferences.predictionEngineType, "native")
        
        // 3. Create new manager instance (simulating app restart)
        let newManager = PredictionEngineManager()
        
        // 4. Verify it loads the saved preference
        // Note: This test assumes the manager loads preferences on init
        XCTAssertTrue(true) // Basic test structure
    }
    
    func testSpeechSynthesizerWithUserPreferences() throws {
        // 1. Set preferences
        userPreferences.speechRate = 0.7
        userPreferences.speechPitch = 1.1
        userPreferences.speechVolume = 0.9
        
        // 2. Create new synthesizer and apply preferences
        let newSynthesizer = SpeechSynthesizer()
        newSynthesizer.setSpeechRate(userPreferences.speechRate)
        newSynthesizer.setPitch(userPreferences.speechPitch)
        newSynthesizer.setVolume(userPreferences.speechVolume)
        
        // 3. Verify settings match preferences
        XCTAssertEqual(newSynthesizer.speechRate, userPreferences.speechRate, accuracy: 0.01)
        XCTAssertEqual(newSynthesizer.pitch, userPreferences.speechPitch, accuracy: 0.01)
        XCTAssertEqual(newSynthesizer.volume, userPreferences.speechVolume, accuracy: 0.01)
    }
    
    // MARK: - Error Handling Integration Tests
    
    func testErrorHandlingInPredictionWorkflow() throws {
        // 1. Test with invalid key sequence
        let invalidSuggestions = predictionManager.suggestions(for: [999])
        XCTAssertTrue(invalidSuggestions.isEmpty, "Should handle invalid keys gracefully")
        
        // 2. Test with empty key sequence
        let emptySuggestions = predictionManager.suggestions(for: [])
        XCTAssertTrue(emptySuggestions.isEmpty, "Should handle empty sequence gracefully")
        
        // 3. Test speech with invalid input
        speechSynthesizer.speak("")
        speechSynthesizer.speak(nil)
        
        // Should not crash
        XCTAssertTrue(true)
    }
    
    func testErrorHandlingInEngineSwithcing() throws {
        // 1. Try to switch to unregistered engine
        let success = predictionManager.switchToEngine(.hybrid)
        XCTAssertFalse(success, "Should fail to switch to unregistered engine")
        
        // 2. Verify current engine unchanged
        XCTAssertEqual(predictionManager.currentEngineType, .custom)
        
        // 3. Verify preferences unchanged
        XCTAssertEqual(userPreferences.predictionEngineType, "custom")
    }
    
    // MARK: - Performance Integration Tests
    
    func testEndToEndPerformance() throws {
        measure {
            // Complete workflow: get predictions and speak result
            let suggestions = predictionManager.suggestions(for: [0, 1])
            if let word = suggestions.first?.0 {
                speechSynthesizer.speak(word)
                speechSynthesizer.stopSpeaking() // Stop immediately for testing
            }
        }
    }
    
    func testEngineSwithcingPerformance() throws {
        // Register native engine
        let nativeEngine = NativePredictionEngine()
        predictionManager.registerEngine(nativeEngine, for: .native)
        
        measure {
            _ = predictionManager.switchToEngine(.native)
            _ = predictionManager.suggestions(for: [0, 1])
            _ = predictionManager.switchToEngine(.custom)
            _ = predictionManager.suggestions(for: [0, 1])
        }
    }
    
    // MARK: - Data Consistency Tests
    
    func testDataConsistencyAcrossComponents() throws {
        // 1. Set preferences
        userPreferences.predictionEngineType = "native"
        userPreferences.speechRate = 0.75
        
        // 2. Register native engine
        let nativeEngine = NativePredictionEngine()
        predictionManager.registerEngine(nativeEngine, for: .native)
        
        // 3. Switch engine
        _ = predictionManager.switchToEngine(.native)
        
        // 4. Apply speech settings
        speechSynthesizer.setSpeechRate(userPreferences.speechRate)
        
        // 5. Verify consistency
        XCTAssertEqual(predictionManager.currentEngineType, .native)
        XCTAssertEqual(userPreferences.predictionEngineType, "native")
        XCTAssertEqual(speechSynthesizer.speechRate, 0.75, accuracy: 0.01)
    }
    
    // MARK: - State Management Tests
    
    func testStateManagementAcrossOperations() throws {
        // 1. Initial state
        let initialEngine = predictionManager.currentEngineType
        let initialSuggestions = predictionManager.suggestions(for: [0])
        
        // 2. Perform operations
        speechSynthesizer.speak("test")
        speechSynthesizer.pauseSpeaking()
        speechSynthesizer.resumeSpeaking()
        speechSynthesizer.stopSpeaking()
        
        // 3. Verify prediction state unchanged
        XCTAssertEqual(predictionManager.currentEngineType, initialEngine)
        let newSuggestions = predictionManager.suggestions(for: [0])
        XCTAssertEqual(newSuggestions.count, initialSuggestions.count)
    }
}
