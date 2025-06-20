//
//  UserPreferencesTests.swift
//  SwipeSpeakTests
//
//  Created by Testing Implementation on 20/06/2025.
//  Copyright © 2025 TeamGleason. All rights reserved.
//

import XCTest
@testable import SwipeSpeak

final class UserPreferencesTests: XCTestCase {
    
    var userPreferences: UserPreferences!
    
    override func setUpWithError() throws {
        userPreferences = UserPreferences.shared
        
        // Clear any existing preferences for clean testing
        UserDefaults.standard.removeObject(forKey: "predictionEngineType")
        UserDefaults.standard.removeObject(forKey: "keyboardLayout")
        UserDefaults.standard.removeObject(forKey: "speechRate")
        UserDefaults.standard.removeObject(forKey: "speechPitch")
        UserDefaults.standard.removeObject(forKey: "speechVolume")
        UserDefaults.standard.removeObject(forKey: "selectedVoiceIdentifier")
    }
    
    override func tearDownWithError() throws {
        // Clean up after tests
        UserDefaults.standard.removeObject(forKey: "predictionEngineType")
        UserDefaults.standard.removeObject(forKey: "keyboardLayout")
        UserDefaults.standard.removeObject(forKey: "speechRate")
        UserDefaults.standard.removeObject(forKey: "speechPitch")
        UserDefaults.standard.removeObject(forKey: "speechVolume")
        UserDefaults.standard.removeObject(forKey: "selectedVoiceIdentifier")
    }
    
    // MARK: - Singleton Tests
    
    func testSharedInstance() throws {
        let prefs1 = UserPreferences.shared
        let prefs2 = UserPreferences.shared
        XCTAssertTrue(prefs1 === prefs2, "UserPreferences should be a singleton")
    }
    
    // MARK: - Prediction Engine Type Tests
    
    func testPredictionEngineTypeDefault() throws {
        // Should default to custom engine
        XCTAssertNil(userPreferences.predictionEngineType, "Should be nil initially")
    }
    
    func testPredictionEngineTypePersistence() throws {
        userPreferences.predictionEngineType = "native"
        XCTAssertEqual(userPreferences.predictionEngineType, "native")
        
        // Create new instance to test persistence
        let newPrefs = UserPreferences()
        XCTAssertEqual(newPrefs.predictionEngineType, "native")
    }
    
    func testPredictionEngineTypeValidValues() throws {
        let validTypes = ["custom", "native", "hybrid"]
        
        for type in validTypes {
            userPreferences.predictionEngineType = type
            XCTAssertEqual(userPreferences.predictionEngineType, type)
        }
    }
    
    // MARK: - Keyboard Layout Tests
    
    func testKeyboardLayoutDefault() throws {
        // Should have a default keyboard layout
        XCTAssertNotNil(userPreferences.keyboardLayout)
    }
    
    func testKeyboardLayoutPersistence() throws {
        let originalLayout = userPreferences.keyboardLayout
        
        // Change to a different layout
        let newLayout: KeyboardLayout = (originalLayout == .keys4) ? .keys6 : .keys4
        userPreferences.keyboardLayout = newLayout
        
        XCTAssertEqual(userPreferences.keyboardLayout, newLayout)
        
        // Create new instance to test persistence
        let newPrefs = UserPreferences()
        XCTAssertEqual(newPrefs.keyboardLayout, newLayout)
    }
    
    // MARK: - Speech Settings Tests
    
    func testSpeechRateDefault() throws {
        // Should have a reasonable default speech rate
        let rate = userPreferences.speechRate
        XCTAssertGreaterThan(rate, 0.0)
        XCTAssertLessThanOrEqual(rate, 1.0)
    }
    
    func testSpeechRatePersistence() throws {
        let testRate: Float = 0.75
        userPreferences.speechRate = testRate
        XCTAssertEqual(userPreferences.speechRate, testRate, accuracy: 0.01)
        
        // Create new instance to test persistence
        let newPrefs = UserPreferences()
        XCTAssertEqual(newPrefs.speechRate, testRate, accuracy: 0.01)
    }
    
    func testSpeechPitchDefault() throws {
        // Should have a reasonable default speech pitch
        let pitch = userPreferences.speechPitch
        XCTAssertGreaterThan(pitch, 0.0)
        XCTAssertLessThanOrEqual(pitch, 2.0)
    }
    
    func testSpeechPitchPersistence() throws {
        let testPitch: Float = 1.25
        userPreferences.speechPitch = testPitch
        XCTAssertEqual(userPreferences.speechPitch, testPitch, accuracy: 0.01)
        
        // Create new instance to test persistence
        let newPrefs = UserPreferences()
        XCTAssertEqual(newPrefs.speechPitch, testPitch, accuracy: 0.01)
    }
    
    func testSpeechVolumeDefault() throws {
        // Should have a reasonable default speech volume
        let volume = userPreferences.speechVolume
        XCTAssertGreaterThanOrEqual(volume, 0.0)
        XCTAssertLessThanOrEqual(volume, 1.0)
    }
    
    func testSpeechVolumePersistence() throws {
        let testVolume: Float = 0.8
        userPreferences.speechVolume = testVolume
        XCTAssertEqual(userPreferences.speechVolume, testVolume, accuracy: 0.01)
        
        // Create new instance to test persistence
        let newPrefs = UserPreferences()
        XCTAssertEqual(newPrefs.speechVolume, testVolume, accuracy: 0.01)
    }
    
    // MARK: - Voice Selection Tests
    
    func testSelectedVoiceIdentifierDefault() throws {
        // Should be nil initially (will use system default)
        XCTAssertNil(userPreferences.selectedVoiceIdentifier)
    }
    
    func testSelectedVoiceIdentifierPersistence() throws {
        let testIdentifier = "com.apple.ttsbundle.Samantha-compact"
        userPreferences.selectedVoiceIdentifier = testIdentifier
        XCTAssertEqual(userPreferences.selectedVoiceIdentifier, testIdentifier)
        
        // Create new instance to test persistence
        let newPrefs = UserPreferences()
        XCTAssertEqual(newPrefs.selectedVoiceIdentifier, testIdentifier)
    }
    
    // MARK: - Edge Cases Tests
    
    func testInvalidSpeechRateValues() throws {
        // Test negative value
        userPreferences.speechRate = -1.0
        XCTAssertGreaterThanOrEqual(userPreferences.speechRate, 0.0)
        
        // Test extremely high value
        userPreferences.speechRate = 10.0
        XCTAssertLessThanOrEqual(userPreferences.speechRate, 1.0)
    }
    
    func testInvalidSpeechPitchValues() throws {
        // Test negative value
        userPreferences.speechPitch = -1.0
        XCTAssertGreaterThanOrEqual(userPreferences.speechPitch, 0.5)
        
        // Test extremely high value
        userPreferences.speechPitch = 10.0
        XCTAssertLessThanOrEqual(userPreferences.speechPitch, 2.0)
    }
    
    func testInvalidSpeechVolumeValues() throws {
        // Test negative value
        userPreferences.speechVolume = -1.0
        XCTAssertGreaterThanOrEqual(userPreferences.speechVolume, 0.0)
        
        // Test value above 1.0
        userPreferences.speechVolume = 2.0
        XCTAssertLessThanOrEqual(userPreferences.speechVolume, 1.0)
    }
    
    // MARK: - Multiple Property Tests
    
    func testMultiplePropertiesSimultaneously() throws {
        userPreferences.predictionEngineType = "native"
        userPreferences.speechRate = 0.6
        userPreferences.speechPitch = 1.3
        userPreferences.speechVolume = 0.9
        userPreferences.selectedVoiceIdentifier = "test.voice.identifier"
        
        XCTAssertEqual(userPreferences.predictionEngineType, "native")
        XCTAssertEqual(userPreferences.speechRate, 0.6, accuracy: 0.01)
        XCTAssertEqual(userPreferences.speechPitch, 1.3, accuracy: 0.01)
        XCTAssertEqual(userPreferences.speechVolume, 0.9, accuracy: 0.01)
        XCTAssertEqual(userPreferences.selectedVoiceIdentifier, "test.voice.identifier")
    }
    
    // MARK: - Performance Tests
    
    func testPreferencesAccessPerformance() throws {
        measure {
            for _ in 0..<100 {
                _ = userPreferences.speechRate
                _ = userPreferences.speechPitch
                _ = userPreferences.speechVolume
                _ = userPreferences.predictionEngineType
            }
        }
    }
    
    func testPreferencesWritePerformance() throws {
        measure {
            for i in 0..<100 {
                userPreferences.speechRate = Float(i % 10) / 10.0
            }
        }
    }
}
