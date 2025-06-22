//
//  UserPreferencesTests.swift
//  SwipeSpeakTests
//
//  Created by Testing Implementation on 20/06/2025.
//  Copyright © 2025 TeamGleason. All rights reserved.
//

import XCTest
@testable import SwipeSpeak

@MainActor
final class UserPreferencesTests: XCTestCase {
    
    var userPreferences: UserPreferences!
    
    override func setUpWithError() throws {
        userPreferences = UserPreferences.shared
        
        // Clear any existing preferences for clean testing
        UserDefaults.standard.removeObject(forKey: "predictionEngineType")
        UserDefaults.standard.removeObject(forKey: "keyboardLayout")
        UserDefaults.standard.removeObject(forKey: "speechRate")
        UserDefaults.standard.removeObject(forKey: "speechVolume")
        UserDefaults.standard.removeObject(forKey: "voiceIdentifier")
    }
    
    override func tearDownWithError() throws {
        // Clean up after tests
        UserDefaults.standard.removeObject(forKey: "predictionEngineType")
        UserDefaults.standard.removeObject(forKey: "keyboardLayout")
        UserDefaults.standard.removeObject(forKey: "speechRate")
        UserDefaults.standard.removeObject(forKey: "speechVolume")
        UserDefaults.standard.removeObject(forKey: "voiceIdentifier")
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

        // Test persistence by checking UserDefaults directly since constructor is private
        XCTAssertEqual(UserDefaults.standard.string(forKey: "predictionEngineType"), "native")
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

        // Test persistence by checking UserDefaults directly since constructor is private
        XCTAssertEqual(UserDefaults.standard.integer(forKey: "keyboardLayout"), newLayout.rawValue)
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

        // Test persistence by checking UserDefaults directly since constructor is private
        XCTAssertEqual(UserDefaults.standard.float(forKey: "speechRate"), testRate, accuracy: 0.01)
    }
    
    // Note: speechPitch property doesn't exist in current implementation
    
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

        // Test persistence by checking UserDefaults directly since constructor is private
        XCTAssertEqual(UserDefaults.standard.float(forKey: "speechVolume"), testVolume, accuracy: 0.01)
    }
    
    // MARK: - Voice Selection Tests
    
    func testVoiceIdentifierDefault() throws {
        // Should be nil initially (will use system default)
        XCTAssertNil(userPreferences.voiceIdentifier)
    }

    func testVoiceIdentifierPersistence() throws {
        let testIdentifier = "com.apple.ttsbundle.Samantha-compact"
        userPreferences.voiceIdentifier = testIdentifier
        XCTAssertEqual(userPreferences.voiceIdentifier, testIdentifier)

        // Test persistence by checking UserDefaults directly since constructor is private
        XCTAssertEqual(UserDefaults.standard.string(forKey: "voiceIdentifier"), testIdentifier)
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
    
    // Note: speechPitch property doesn't exist in current implementation
    
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
        userPreferences.speechVolume = 0.9
        userPreferences.voiceIdentifier = "test.voice.identifier"

        XCTAssertEqual(userPreferences.predictionEngineType, "native")
        XCTAssertEqual(userPreferences.speechRate, 0.6, accuracy: 0.01)
        XCTAssertEqual(userPreferences.speechVolume, 0.9, accuracy: 0.01)
        XCTAssertEqual(userPreferences.voiceIdentifier, "test.voice.identifier")
    }
    
    // MARK: - Performance Tests
    
    func testPreferencesAccessPerformance() throws {
        measure {
            for _ in 0..<100 {
                _ = userPreferences.speechRate
                _ = userPreferences.speechVolume
                _ = userPreferences.predictionEngineType
                _ = userPreferences.voiceIdentifier
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
