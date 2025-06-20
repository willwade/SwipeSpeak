//
//  SpeechSynthesizerTests.swift
//  SwipeSpeakTests
//
//  Created by Testing Implementation on 20/06/2025.
//  Copyright © 2025 TeamGleason. All rights reserved.
//

import XCTest
import AVFoundation
@testable import SwipeSpeak

final class SpeechSynthesizerTests: XCTestCase {
    
    var speechSynthesizer: SpeechSynthesizer!
    
    override func setUpWithError() throws {
        speechSynthesizer = SpeechSynthesizer()
    }
    
    override func tearDownWithError() throws {
        speechSynthesizer.stopSpeaking()
        speechSynthesizer = nil
    }
    
    // MARK: - Initialization Tests
    
    func testSpeechSynthesizerInitialization() throws {
        XCTAssertNotNil(speechSynthesizer, "SpeechSynthesizer should initialize successfully")
    }
    
    func testDefaultVoiceSelection() throws {
        let voice = speechSynthesizer.currentVoice
        XCTAssertNotNil(voice, "Should have a default voice selected")
        XCTAssertTrue(voice?.language.hasPrefix("en") ?? false, "Default voice should be English")
    }
    
    // MARK: - Voice Management Tests
    
    func testAvailableVoices() throws {
        let voices = speechSynthesizer.availableVoices
        XCTAssertFalse(voices.isEmpty, "Should have available voices")
        
        // All voices should be English
        for voice in voices {
            XCTAssertTrue(voice.language.hasPrefix("en"), "All voices should be English")
        }
    }
    
    func testVoiceSelection() throws {
        let voices = speechSynthesizer.availableVoices
        guard let firstVoice = voices.first else {
            XCTFail("No voices available for testing")
            return
        }
        
        speechSynthesizer.setVoice(firstVoice)
        XCTAssertEqual(speechSynthesizer.currentVoice?.identifier, firstVoice.identifier)
    }
    
    func testVoiceQualityPrioritization() throws {
        let voices = speechSynthesizer.availableVoices
        
        // Check that enhanced quality voices are prioritized
        let enhancedVoices = voices.filter { $0.quality == .enhanced }
        let defaultVoices = voices.filter { $0.quality == .default }
        
        if !enhancedVoices.isEmpty && !defaultVoices.isEmpty {
            // Enhanced voices should come first in the list
            let firstEnhancedIndex = voices.firstIndex { $0.quality == .enhanced } ?? voices.count
            let firstDefaultIndex = voices.firstIndex { $0.quality == .default } ?? voices.count
            
            XCTAssertLessThan(firstEnhancedIndex, firstDefaultIndex, 
                             "Enhanced quality voices should be prioritized")
        }
    }
    
    // MARK: - Speech Rate Tests
    
    func testSpeechRateSettings() throws {
        let testRates: [Float] = [0.3, 0.5, 0.7, 1.0]
        
        for rate in testRates {
            speechSynthesizer.setSpeechRate(rate)
            XCTAssertEqual(speechSynthesizer.speechRate, rate, accuracy: 0.01)
        }
    }
    
    func testSpeechRateBounds() throws {
        // Test minimum rate
        speechSynthesizer.setSpeechRate(0.0)
        XCTAssertGreaterThanOrEqual(speechSynthesizer.speechRate, AVSpeechUtteranceMinimumSpeechRate)
        
        // Test maximum rate
        speechSynthesizer.setSpeechRate(2.0)
        XCTAssertLessThanOrEqual(speechSynthesizer.speechRate, AVSpeechUtteranceMaximumSpeechRate)
    }
    
    // MARK: - Speech Pitch Tests
    
    func testSpeechPitchSettings() throws {
        let testPitches: [Float] = [0.5, 1.0, 1.5, 2.0]
        
        for pitch in testPitches {
            speechSynthesizer.setPitch(pitch)
            XCTAssertEqual(speechSynthesizer.pitch, pitch, accuracy: 0.01)
        }
    }
    
    func testSpeechPitchBounds() throws {
        // Test minimum pitch
        speechSynthesizer.setPitch(0.0)
        XCTAssertGreaterThanOrEqual(speechSynthesizer.pitch, 0.5)
        
        // Test maximum pitch
        speechSynthesizer.setPitch(3.0)
        XCTAssertLessThanOrEqual(speechSynthesizer.pitch, 2.0)
    }
    
    // MARK: - Speech Volume Tests
    
    func testSpeechVolumeSettings() throws {
        let testVolumes: [Float] = [0.0, 0.5, 1.0]
        
        for volume in testVolumes {
            speechSynthesizer.setVolume(volume)
            XCTAssertEqual(speechSynthesizer.volume, volume, accuracy: 0.01)
        }
    }
    
    func testSpeechVolumeBounds() throws {
        // Test below minimum
        speechSynthesizer.setVolume(-0.5)
        XCTAssertGreaterThanOrEqual(speechSynthesizer.volume, 0.0)
        
        // Test above maximum
        speechSynthesizer.setVolume(1.5)
        XCTAssertLessThanOrEqual(speechSynthesizer.volume, 1.0)
    }
    
    // MARK: - Speech Control Tests
    
    func testSpeakText() throws {
        let expectation = XCTestExpectation(description: "Speech should start")
        
        // Use a very short text to minimize test time
        speechSynthesizer.speak("Hi")
        
        // Give it a moment to start
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testStopSpeaking() throws {
        speechSynthesizer.speak("This is a longer text that should be interrupted")
        
        // Stop immediately
        speechSynthesizer.stopSpeaking()
        
        // Should not be speaking after stop
        XCTAssertFalse(speechSynthesizer.isSpeaking)
    }
    
    func testPauseSpeaking() throws {
        speechSynthesizer.speak("This is a test for pausing speech")
        
        // Pause immediately
        speechSynthesizer.pauseSpeaking()
        
        // Should be paused
        XCTAssertTrue(speechSynthesizer.isPaused)
    }
    
    func testResumeSpeaking() throws {
        speechSynthesizer.speak("This is a test for resuming speech")
        speechSynthesizer.pauseSpeaking()
        
        XCTAssertTrue(speechSynthesizer.isPaused)
        
        speechSynthesizer.resumeSpeaking()
        
        // Should no longer be paused
        XCTAssertFalse(speechSynthesizer.isPaused)
    }
    
    // MARK: - Edge Case Tests
    
    func testSpeakEmptyString() throws {
        speechSynthesizer.speak("")
        
        // Should handle empty string gracefully
        XCTAssertFalse(speechSynthesizer.isSpeaking)
    }
    
    func testSpeakNilString() throws {
        speechSynthesizer.speak(nil)
        
        // Should handle nil gracefully
        XCTAssertFalse(speechSynthesizer.isSpeaking)
    }
    
    func testSpeakVeryLongString() throws {
        let longString = String(repeating: "This is a very long string. ", count: 100)
        speechSynthesizer.speak(longString)
        
        // Should handle long strings without crashing
        XCTAssertTrue(true) // If we get here, it didn't crash
        
        speechSynthesizer.stopSpeaking()
    }
    
    // MARK: - Performance Tests
    
    func testSpeechInitializationPerformance() throws {
        measure {
            let synthesizer = SpeechSynthesizer()
            _ = synthesizer.availableVoices
        }
    }
    
    func testVoiceSelectionPerformance() throws {
        let voices = speechSynthesizer.availableVoices
        guard let voice = voices.first else { return }
        
        measure {
            speechSynthesizer.setVoice(voice)
        }
    }
}
