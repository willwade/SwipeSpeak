//
//  PredictionEngine.swift
//  SwipeSpeak
//
//  Created by Modernization on 20/06/2025.
//  Copyright © 2025 TeamGleason. All rights reserved.
//

import Foundation

/// Enum representing different types of prediction engines
enum PredictionEngineType: String, CaseIterable {
    case custom = "custom"
    case native = "native"
    case hybrid = "hybrid"
    
    var displayName: String {
        switch self {
        case .custom:
            return "Custom Trie Engine"
        case .native:
            return "iOS Native Engine"
        case .hybrid:
            return "Hybrid Engine"
        }
    }
    
    var description: String {
        switch self {
        case .custom:
            return "Fast offline prediction using custom dictionary"
        case .native:
            return "iOS system prediction with spell checking"
        case .hybrid:
            return "Combines both engines for best results"
        }
    }
}

/// Protocol defining the interface for word prediction engines
protocol PredictionEngine {
    /// The type of this prediction engine
    var engineType: PredictionEngineType { get }
    
    /// Whether this engine is currently available for use
    var isAvailable: Bool { get }
    
    /// Get word suggestions for a given key sequence
    /// - Parameter keySequence: Array of integers representing key presses
    /// - Returns: Array of tuples containing (word, frequency/score)
    func suggestions(for keySequence: [Int]) -> [(String, Int)]
    
    /// Insert a new word into the engine's dictionary
    /// - Parameters:
    ///   - word: The word to insert
    ///   - frequency: The frequency/score for the word
    /// - Throws: WordPredictionError if the word cannot be inserted
    func insert(_ word: String, frequency: Int) throws
    
    /// Check if a word exists in the engine's dictionary
    /// - Parameter word: The word to check
    /// - Returns: True if the word exists, false otherwise
    func contains(_ word: String) -> Bool
    
    /// Set the key letter grouping for the engine
    /// - Parameters:
    ///   - grouping: Array of strings representing letter groups for each key
    ///   - twoStrokes: Whether this is a two-stroke keyboard layout
    func setKeyLetterGrouping(_ grouping: [String], twoStrokes: Bool)
    
    /// Get performance metrics for this engine (optional)
    var performanceMetrics: PredictionEngineMetrics? { get }
}

/// Performance metrics for prediction engines
struct PredictionEngineMetrics {
    let averageResponseTime: TimeInterval
    let totalQueries: Int
    let cacheHitRate: Double
    let memoryUsage: Int // in bytes
    let lastUpdated: Date
}

/// Manager class for handling multiple prediction engines
class PredictionEngineManager {
    static let shared = PredictionEngineManager()

    var engines: [PredictionEngineType: PredictionEngine] = [:]
    private var currentEngineType: PredictionEngineType = .custom
    
    private init() {
        setupEngines()
    }
    
    /// Current active prediction engine
    var currentEngine: PredictionEngine? {
        return engines[currentEngineType]
    }
    
    /// Switch to a different prediction engine
    /// - Parameter type: The type of engine to switch to
    /// - Returns: True if switch was successful, false otherwise
    func switchToEngine(_ type: PredictionEngineType) -> Bool {
        guard let engine = engines[type], engine.isAvailable else {
            return false
        }
        
        currentEngineType = type
        UserPreferences.shared.predictionEngineType = type.rawValue
        
        // Copy key letter grouping from current engine if needed
        if let currentEngine = engines[.custom] as? WordPredictionEngine {
            engine.setKeyLetterGrouping([], twoStrokes: false) // Will be set properly by MainTVC
        }
        
        return true
    }
    
    /// Get all available engines
    var availableEngines: [PredictionEngine] {
        return engines.values.filter { $0.isAvailable }
    }
    
    /// Register a new prediction engine
    /// - Parameters:
    ///   - engine: The engine to register
    ///   - type: The type of the engine
    func registerEngine(_ engine: PredictionEngine, for type: PredictionEngineType) {
        engines[type] = engine
    }
    
    private func setupEngines() {
        // Register the existing custom engine
        let customEngine = WordPredictionEngine()
        registerEngine(customEngine, for: .custom)
        
        // Native engine will be registered when created
        // Hybrid engine will be registered when created
        
        // Load user preference
        if let savedType = UserPreferences.shared.predictionEngineType,
           let type = PredictionEngineType(rawValue: savedType) {
            _ = switchToEngine(type)
        }
    }
}

/// Extension to make WordPredictionEngine conform to PredictionEngine protocol
extension WordPredictionEngine: PredictionEngine {
    var engineType: PredictionEngineType {
        return .custom
    }
    
    var isAvailable: Bool {
        return true
    }
    
    var performanceMetrics: PredictionEngineMetrics? {
        return PredictionEngineMetrics(
            averageResponseTime: 0.001, // Very fast for Trie
            totalQueries: 0, // Would need to track this
            cacheHitRate: 1.0, // Trie is essentially a cache
            memoryUsage: 0, // Would need to calculate
            lastUpdated: Date()
        )
    }
}
