//
//  NativePredictionEngine.swift
//  SwipeSpeak
//
//  Created by Modernization on 20/06/2025.
//  Copyright © 2025 TeamGleason. All rights reserved.
//

import Foundation
import UIKit

/// Native iOS prediction engine using UITextChecker and system APIs
class NativePredictionEngine: PredictionEngine {
    
    // MARK: - Properties
    
    private let textChecker = UITextChecker()
    private let spellChecker = NSSpellChecker.shared
    private var keyLetterGrouping: [Character: Int] = [:]
    private var isTwoStrokes = false
    
    // Cache for performance
    private var suggestionCache: [String: [(String, Int)]] = [:]
    private let cacheQueue = DispatchQueue(label: "com.swipespeak.prediction.cache", attributes: .concurrent)
    
    // Performance tracking
    private var queryCount = 0
    private var totalResponseTime: TimeInterval = 0
    private var cacheHits = 0
    
    // MARK: - PredictionEngine Protocol
    
    var engineType: PredictionEngineType {
        return .native
    }
    
    var isAvailable: Bool {
        // Check if UITextChecker is available (should be on iOS 15+)
        return UITextChecker.availableLanguages.contains("en")
    }
    
    var performanceMetrics: PredictionEngineMetrics? {
        let avgResponseTime = queryCount > 0 ? totalResponseTime / Double(queryCount) : 0
        let hitRate = queryCount > 0 ? Double(cacheHits) / Double(queryCount) : 0
        
        return PredictionEngineMetrics(
            averageResponseTime: avgResponseTime,
            totalQueries: queryCount,
            cacheHitRate: hitRate,
            memoryUsage: estimateMemoryUsage(),
            lastUpdated: Date()
        )
    }
    
    func suggestions(for keySequence: [Int]) -> [(String, Int)] {
        let startTime = CFAbsoluteTimeGetCurrent()
        defer {
            let endTime = CFAbsoluteTimeGetCurrent()
            totalResponseTime += (endTime - startTime)
            queryCount += 1
        }
        
        guard !keySequence.isEmpty else { return [] }
        
        let cacheKey = keySequence.map(String.init).joined(separator:",")
        
        // Check cache first
        if let cachedResult = getCachedSuggestions(for: cacheKey) {
            cacheHits += 1
            return cachedResult
        }
        
        let suggestions = generateSuggestions(for: keySequence)
        
        // Cache the result
        setCachedSuggestions(suggestions, for: cacheKey)
        
        return suggestions
    }
    
    func insert(_ word: String, frequency: Int) throws {
        // For native engine, we can't directly insert into system dictionary
        // But we can add to user dictionary if needed
        guard isWordValid(word) else {
            throw WordPredictionError.unsupportedWord(invalidChar: word.first ?? Character(""))
        }
        
        // Note: iOS doesn't provide a public API to add words to user dictionary
        // This would be a limitation of the native engine
        print("Note: Native engine cannot add custom words to system dictionary")
    }
    
    func contains(_ word: String) -> Bool {
        // Check if word exists in system dictionary
        let range = NSRange(location: 0, length: word.count)
        let misspelledRange = textChecker.rangeOfMisspelledWord(
            in: word,
            range: range,
            startingAt: 0,
            wrap: false,
            language: "en"
        )
        
        return misspelledRange.location == NSNotFound
    }
    
    func setKeyLetterGrouping(_ grouping: [String], twoStrokes: Bool) {
        keyLetterGrouping = [:]
        self.isTwoStrokes = twoStrokes
        
        if twoStrokes {
            // For two-stroke keyboards, map each letter to its ASCII value
            for letterValue in UnicodeScalar("a").value...UnicodeScalar("z").value {
                if let scalar = UnicodeScalar(letterValue) {
                    keyLetterGrouping[Character(scalar)] = Int(letterValue)
                }
            }
        } else {
            // For regular keyboards, map letters to key indices
            for (index, group) in grouping.enumerated() {
                for letter in group {
                    keyLetterGrouping[letter] = index
                }
            }
        }
        
        // Clear cache when grouping changes
        clearCache()
    }
    
    // MARK: - Private Methods
    
    private func generateSuggestions(for keySequence: [Int]) -> [(String, Int)] {
        var suggestions: [(String, Int)] = []
        
        if isTwoStrokes {
            // For two-stroke keyboards, convert key sequence to letters
            let letters = keySequence.compactMap { UnicodeScalar($0) }.map { Character($0) }
            let partialWord = String(letters)
            
            suggestions = getSuggestionsForPartialWord(partialWord)
        } else {
            // For regular keyboards, generate possible letter combinations
            let possibleWords = generatePossibleWords(from: keySequence)
            
            for word in possibleWords {
                let wordSuggestions = getSuggestionsForPartialWord(word)
                suggestions.append(contentsOf: wordSuggestions)
            }
        }
        
        // Remove duplicates and sort by score
        let uniqueSuggestions = Dictionary(grouping: suggestions, by: { $0.0 })
            .compactMapValues { $0.max(by: { $0.1 < $1.1 }) }
            .values
            .sorted { $0.1 > $1.1 }
        
        return Array(uniqueSuggestions.prefix(10)) // Limit to top 10
    }
    
    private func generatePossibleWords(from keySequence: [Int]) -> [String] {
        guard !keySequence.isEmpty else { return [] }
        
        var possibleWords: [String] = [""]
        
        for key in keySequence {
            var newWords: [String] = []
            
            // Find all letters for this key
            let lettersForKey = keyLetterGrouping.compactMap { (letter, keyIndex) -> Character? in
                return keyIndex == key ? letter : nil
            }
            
            for word in possibleWords {
                for letter in lettersForKey {
                    newWords.append(word + String(letter))
                }
            }
            
            possibleWords = newWords
        }
        
        return possibleWords
    }
    
    private func getSuggestionsForPartialWord(_ partialWord: String) -> [(String, Int)] {
        guard !partialWord.isEmpty else { return [] }
        
        var suggestions: [(String, Int)] = []
        
        // Use UITextChecker for completions
        if #available(iOS 15.0, *) {
            let completions = textChecker.completions(
                forPartialWordRange: NSRange(location: 0, length: partialWord.count),
                in: partialWord,
                language: "en"
            ) ?? []
            
            for (index, completion) in completions.enumerated() {
                // Score based on position (earlier = higher score)
                let score = max(1000 - (index * 10), 1)
                suggestions.append((completion, score))
            }
        }
        
        // Use NSSpellChecker for additional suggestions
        let spellSuggestions = spellChecker.completions(forPartialWordRange: NSRange(location: 0, length: partialWord.count), in: partialWord, language: "en") ?? []
        
        for (index, suggestion) in spellSuggestions.enumerated() {
            // Lower score for spell checker suggestions
            let score = max(500 - (index * 5), 1)
            suggestions.append((suggestion, score))
        }
        
        return suggestions
    }
    
    private func isWordValid(_ word: String) -> Bool {
        return word.range(of: "^[A-Za-z]+$", options: .regularExpression) != nil
    }
    
    // MARK: - Cache Management
    
    private func getCachedSuggestions(for key: String) -> [(String, Int)]? {
        return cacheQueue.sync {
            return suggestionCache[key]
        }
    }
    
    private func setCachedSuggestions(_ suggestions: [(String, Int)], for key: String) {
        cacheQueue.async(flags: .barrier) {
            self.suggestionCache[key] = suggestions
            
            // Limit cache size
            if self.suggestionCache.count > 1000 {
                let keysToRemove = Array(self.suggestionCache.keys.prefix(100))
                for keyToRemove in keysToRemove {
                    self.suggestionCache.removeValue(forKey: keyToRemove)
                }
            }
        }
    }
    
    private func clearCache() {
        cacheQueue.async(flags: .barrier) {
            self.suggestionCache.removeAll()
        }
    }
    
    private func estimateMemoryUsage() -> Int {
        return cacheQueue.sync {
            let cacheSize = suggestionCache.reduce(0) { total, entry in
                let keySize = entry.key.utf8.count
                let valueSize = entry.value.reduce(0) { $0 + $1.0.utf8.count + MemoryLayout<Int>.size }
                return total + keySize + valueSize
            }
            return cacheSize + MemoryLayout<NativePredictionEngine>.size
        }
    }
}
