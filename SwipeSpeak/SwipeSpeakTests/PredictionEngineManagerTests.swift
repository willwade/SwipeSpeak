//
//  PredictionEngineManagerTests.swift
//  SwipeSpeakTests
//
//  Created by Testing Implementation on 20/06/2025.
//  Copyright © 2025 TeamGleason. All rights reserved.
//

import XCTest
@testable import SwipeSpeak

final class PredictionEngineManagerTests: XCTestCase {
    
    var manager: PredictionEngineManager!
    
    override func setUpWithError() throws {
        manager = PredictionEngineManager.shared
        
        // Reset to default state
        _ = manager.switchToEngine(.custom)
    }
    
    override func tearDownWithError() throws {
        // Reset to default state
        _ = manager.switchToEngine(.custom)
    }
    
    // MARK: - Singleton Tests
    
    func testSharedInstance() throws {
        let manager1 = PredictionEngineManager.shared
        let manager2 = PredictionEngineManager.shared
        XCTAssertTrue(manager1 === manager2, "PredictionEngineManager should be a singleton")
    }
    
    // MARK: - Engine Registration Tests
    
    func testDefaultEnginesRegistered() throws {
        let availableEngines = manager.availableEngines
        XCTAssertFalse(availableEngines.isEmpty, "Should have at least one engine registered")
        
        // Should have custom engine by default
        let hasCustomEngine = availableEngines.contains { $0.engineType == .custom }
        XCTAssertTrue(hasCustomEngine, "Should have custom engine registered")
    }
    
    func testCurrentEngineInitialization() throws {
        let currentEngine = manager.currentEngine
        XCTAssertNotNil(currentEngine, "Should have a current engine")
        XCTAssertEqual(currentEngine?.engineType, .custom, "Should default to custom engine")
    }
    
    // MARK: - Engine Switching Tests
    
    func testSwitchToCustomEngine() throws {
        let success = manager.switchToEngine(.custom)
        XCTAssertTrue(success, "Should successfully switch to custom engine")
        XCTAssertEqual(manager.currentEngine?.engineType, .custom)
        XCTAssertEqual(manager.currentEngineType, .custom)
    }
    
    func testSwitchToNativeEngine() throws {
        // First register native engine
        let nativeEngine = NativePredictionEngine()
        manager.registerEngine(nativeEngine, for: .native)
        
        let success = manager.switchToEngine(.native)
        XCTAssertTrue(success, "Should successfully switch to native engine")
        XCTAssertEqual(manager.currentEngine?.engineType, .native)
        XCTAssertEqual(manager.currentEngineType, .native)
    }
    
    func testSwitchToUnavailableEngine() throws {
        // Try to switch to an engine that hasn't been registered
        let success = manager.switchToEngine(.hybrid)
        XCTAssertFalse(success, "Should fail to switch to unregistered engine")
        
        // Current engine should remain unchanged
        XCTAssertEqual(manager.currentEngine?.engineType, .custom)
    }
    
    // MARK: - Suggestion Tests
    
    func testSuggestionsFromCurrentEngine() throws {
        let keySequence = [0, 1] // Basic key sequence
        let suggestions = manager.suggestions(for: keySequence)
        
        XCTAssertFalse(suggestions.isEmpty, "Should return suggestions from current engine")
    }
    
    func testSuggestionsAfterEngineSwitch() throws {
        // Register and switch to native engine
        let nativeEngine = NativePredictionEngine()
        manager.registerEngine(nativeEngine, for: .native)
        
        let keySequence = [0, 1]
        
        // Get suggestions from custom engine
        _ = manager.switchToEngine(.custom)
        let customSuggestions = manager.suggestions(for: keySequence)
        
        // Switch to native engine and get suggestions
        _ = manager.switchToEngine(.native)
        let nativeSuggestions = manager.suggestions(for: keySequence)
        
        XCTAssertFalse(customSuggestions.isEmpty, "Custom engine should return suggestions")
        XCTAssertFalse(nativeSuggestions.isEmpty, "Native engine should return suggestions")
    }
    
    // MARK: - Key Letter Grouping Tests
    
    func testSetKeyLetterGrouping() throws {
        let keyLetterGrouping = [
            ["a", "b", "c"],
            ["d", "e", "f"],
            ["g", "h", "i"]
        ]
        
        manager.setKeyLetterGrouping(keyLetterGrouping, twoStrokes: false)
        
        // Test that suggestions work with the new grouping
        let suggestions = manager.suggestions(for: [0])
        XCTAssertFalse(suggestions.isEmpty, "Should return suggestions with new key grouping")
    }
    
    func testTwoStrokesKeyLetterGrouping() throws {
        let keyLetterGrouping = [
            ["a", "b"],
            ["c", "d"],
            ["e", "f"]
        ]
        
        manager.setKeyLetterGrouping(keyLetterGrouping, twoStrokes: true)
        
        // Test that suggestions work with two strokes grouping
        let suggestions = manager.suggestions(for: [0])
        XCTAssertFalse(suggestions.isEmpty, "Should return suggestions with two strokes grouping")
    }
    
    // MARK: - Engine Registration Tests
    
    func testRegisterNewEngine() throws {
        let nativeEngine = NativePredictionEngine()
        manager.registerEngine(nativeEngine, for: .native)
        
        let availableEngines = manager.availableEngines
        let hasNativeEngine = availableEngines.contains { $0.engineType == .native }
        XCTAssertTrue(hasNativeEngine, "Should have native engine after registration")
    }
    
    func testAvailableEnginesCount() throws {
        let initialCount = manager.availableEngines.count
        
        // Register native engine
        let nativeEngine = NativePredictionEngine()
        manager.registerEngine(nativeEngine, for: .native)
        
        let newCount = manager.availableEngines.count
        XCTAssertEqual(newCount, initialCount + 1, "Should have one more available engine")
    }
    
    // MARK: - User Preferences Integration Tests
    
    func testUserPreferencesPersistence() throws {
        // Register native engine
        let nativeEngine = NativePredictionEngine()
        manager.registerEngine(nativeEngine, for: .native)
        
        // Switch to native engine
        _ = manager.switchToEngine(.native)
        
        // Check that preference was saved
        let savedType = UserPreferences.shared.predictionEngineType
        XCTAssertEqual(savedType, PredictionEngineType.native.rawValue)
    }
    
    // MARK: - Performance Tests
    
    func testManagerPerformance() throws {
        let keySequence = [0, 1, 2, 3]
        
        measure {
            _ = manager.suggestions(for: keySequence)
        }
    }
    
    func testEngineSwitchingPerformance() throws {
        // Register native engine
        let nativeEngine = NativePredictionEngine()
        manager.registerEngine(nativeEngine, for: .native)
        
        measure {
            _ = manager.switchToEngine(.native)
            _ = manager.switchToEngine(.custom)
        }
    }
}
