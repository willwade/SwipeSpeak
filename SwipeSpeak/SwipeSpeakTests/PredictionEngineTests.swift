//
//  PredictionEngineTests.swift
//  SwipeSpeakTests
//
//  Created by Testing Implementation on 20/06/2025.
//  Copyright © 2025 TeamGleason. All rights reserved.
//

import XCTest
@testable import SwipeSpeak

@MainActor
final class PredictionEngineTests: XCTestCase {
    
    var customEngine: WordPredictionEngine!
    var nativeEngine: NativePredictionEngine!
    
    override func setUpWithError() throws {
        customEngine = WordPredictionEngine()
        nativeEngine = NativePredictionEngine()
        
        // Setup basic key letter grouping for testing - fix the type
        let keyLetterGrouping = [
            "abc",
            "def",
            "ghi",
            "jkl",
            "mno",
            "pqrs",
            "tuv",
            "wxyz"
        ]

        customEngine.setKeyLetterGrouping(keyLetterGrouping, twoStrokes: false)
        nativeEngine.setKeyLetterGrouping(keyLetterGrouping, twoStrokes: false)
    }
    
    override func tearDownWithError() throws {
        customEngine = nil
        nativeEngine = nil
    }
    
    // MARK: - Custom Engine Tests
    
    func testCustomEngineType() throws {
        XCTAssertEqual(customEngine.engineType, .custom)
    }
    
    func testCustomEngineAvailability() throws {
        XCTAssertTrue(customEngine.isAvailable)
    }
    
    func testCustomEngineBasicSuggestions() throws {
        // Test basic word suggestions
        let suggestions = customEngine.suggestions(for: [0]) // Key 0 = "a", "b", "c"
        XCTAssertFalse(suggestions.isEmpty, "Should return suggestions for valid key sequence")
        
        // Check that suggestions contain words starting with letters from key 0
        let firstSuggestion = suggestions.first?.0 ?? ""
        let firstLetter = firstSuggestion.lowercased().first
        XCTAssertTrue(["a", "b", "c"].contains(String(firstLetter ?? "x")), 
                     "First suggestion should start with a letter from key 0")
    }
    
    func testCustomEngineEmptyKeySequence() throws {
        let suggestions = customEngine.suggestions(for: [])
        XCTAssertTrue(suggestions.isEmpty, "Empty key sequence should return no suggestions")
    }
    
    func testCustomEngineInvalidKeySequence() throws {
        let suggestions = customEngine.suggestions(for: [99]) // Invalid key
        XCTAssertTrue(suggestions.isEmpty, "Invalid key sequence should return no suggestions")
    }
    
    func testCustomEngineMultipleKeys() throws {
        let suggestions = customEngine.suggestions(for: [0, 1]) // "abc" + "def"
        XCTAssertFalse(suggestions.isEmpty, "Should return suggestions for multi-key sequence")
    }
    
    // MARK: - Native Engine Tests
    
    func testNativeEngineType() throws {
        XCTAssertEqual(nativeEngine.engineType, .native)
    }
    
    func testNativeEngineAvailability() throws {
        XCTAssertTrue(nativeEngine.isAvailable)
    }
    
    func testNativeEngineBasicSuggestions() throws {
        let suggestions = nativeEngine.suggestions(for: [0]) // Key 0 = "a", "b", "c"
        XCTAssertFalse(suggestions.isEmpty, "Should return suggestions for valid key sequence")
    }
    
    func testNativeEngineEmptyKeySequence() throws {
        let suggestions = nativeEngine.suggestions(for: [])
        XCTAssertTrue(suggestions.isEmpty, "Empty key sequence should return no suggestions")
    }
    
    func testNativeEnginePerformanceMetrics() throws {
        // Make some queries to generate metrics
        _ = nativeEngine.suggestions(for: [0])
        _ = nativeEngine.suggestions(for: [1])
        _ = nativeEngine.suggestions(for: [0, 1])
        
        let metrics = nativeEngine.performanceMetrics
        XCTAssertNotNil(metrics, "Should provide performance metrics")
        XCTAssertGreaterThan(metrics?.totalQueries ?? 0, 0, "Should track query count")
    }
    
    // MARK: - Engine Comparison Tests
    
    func testEngineConsistency() throws {
        let keySequence = [0, 1] // "abc" + "def"
        
        let customSuggestions = customEngine.suggestions(for: keySequence)
        let nativeSuggestions = nativeEngine.suggestions(for: keySequence)
        
        XCTAssertFalse(customSuggestions.isEmpty, "Custom engine should return suggestions")
        XCTAssertFalse(nativeSuggestions.isEmpty, "Native engine should return suggestions")
        
        // Both engines should return valid words
        for (word, _) in customSuggestions.prefix(3) {
            XCTAssertFalse(word.isEmpty, "Custom engine should not return empty words")
            XCTAssertTrue(word.allSatisfy { $0.isLetter }, "Custom engine should return only letters")
        }
        
        for (word, _) in nativeSuggestions.prefix(3) {
            XCTAssertFalse(word.isEmpty, "Native engine should not return empty words")
            XCTAssertTrue(word.allSatisfy { $0.isLetter }, "Native engine should return only letters")
        }
    }
    
    // MARK: - Performance Tests
    
    func testCustomEnginePerformance() throws {
        let keySequence = [0, 1, 2] // "abc" + "def" + "ghi"
        
        measure {
            _ = customEngine.suggestions(for: keySequence)
        }
    }
    
    func testNativeEnginePerformance() throws {
        let keySequence = [0, 1, 2] // "abc" + "def" + "ghi"
        
        measure {
            _ = nativeEngine.suggestions(for: keySequence)
        }
    }
}
