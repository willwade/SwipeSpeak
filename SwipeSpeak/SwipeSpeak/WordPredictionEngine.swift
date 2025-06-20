//
//  WordPredictionEngine.swift
//  SwipeSpeak
//
//  Created by Xiaoyi Zhang on 7/5/17.
//  Updated by Daniel Tsirulnikov on 1/2/18.
//  Copyright © 2017 TeamGleason. All rights reserved.
//

import Foundation
import UIKit

enum WordPredictionError: Error {
    case unsupportedWord(invalidChar: Character)
}

enum PredictionEngineType: String, CaseIterable {
    case custom = "custom"
    case native = "native"

    var displayName: String {
        switch self {
        case .custom:
            return "Custom"
        case .native:
            return "Native"
        }
    }
}

protocol PredictionEngineProtocol {
    func setKeyLetterGrouping(_ grouping: [String], twoStrokes: Bool)
    func insert(_ word: String, _ frequency: Int) throws
    func contains(_ word: String) -> Bool
    func suggestions(for keyString: [Int]) -> [(String, Int)]
}







// Native prediction engine using iOS built-in text checking
class NativePredictionEngine: PredictionEngineProtocol {

    func setKeyLetterGrouping(_ grouping: [String], twoStrokes: Bool) {
        // Native engine doesn't need key letter grouping
    }

    func insert(_ word: String, _ frequency: Int) throws {
        // Native engine doesn't support custom word insertion
    }

    func contains(_ word: String) -> Bool {
        // For native engine, assume all words are available
        return true
    }

    func suggestions(for keyString: [Int]) -> [(String, Int)] {
        // Convert key sequence to partial word
        let partialWord = convertKeySequenceToPartialWord(keyString)

        // For now, provide some basic completions based on common patterns
        // In a real implementation, this would use iOS text prediction APIs
        let basicCompletions = generateBasicCompletions(for: partialWord)

        // Return with default frequency
        return basicCompletions.enumerated().map { (index, word) in
            (word, 100 - index) // Higher frequency for earlier suggestions
        }
    }

    private func generateBasicCompletions(for partialWord: String) -> [String] {
        // Simple completion logic for testing
        let commonWords = [
            "hello", "help", "here", "have", "how", "home", "happy", "hand",
            "the", "that", "this", "they", "there", "then", "thank", "think",
            "and", "are", "all", "any", "also", "about", "after", "again",
            "you", "your", "yes", "year", "yet", "young", "yesterday",
            "can", "could", "come", "call", "car", "cat", "computer", "cool",
            "will", "with", "what", "when", "where", "why", "who", "work",
            "good", "great", "get", "go", "give", "game", "group", "girl"
        ]

        if partialWord.isEmpty {
            return Array(commonWords.prefix(5))
        }

        // Filter words that start with the partial word
        let matches = commonWords.filter { $0.lowercased().hasPrefix(partialWord.lowercased()) }
        return Array(matches.prefix(5))
    }

    private func convertKeySequenceToPartialWord(_ keyString: [Int]) -> String {
        // This is a simplified conversion - in a real implementation,
        // you would map key sequences to letters based on the keyboard layout
        // For now, return a simple string for testing
        if keyString.isEmpty {
            return ""
        }

        // Simple mapping for testing - this should be replaced with actual keyboard mapping
        let keyToLetter: [Int: String] = [
            2: "abc", 3: "def", 4: "ghi", 5: "jkl", 6: "mno", 7: "pqrs", 8: "tuv", 9: "wxyz"
        ]

        var result = ""
        for key in keyString {
            if let letters = keyToLetter[key] {
                result += String(letters.first ?? "a") // Take first letter for simplicity
            }
        }

        return result
    }
}

class WordPredictionEngine: PredictionEngineProtocol {
    
    // MARK: Classes
    
    private class TrieNode {
        var children = [Int: TrieNode]()
        var words = [(String, Int)]()
    }

    // MARK: Properties

    private var rootNode = TrieNode()
    private var words = [String: Int]()
    private var keyLetterGrouping = [Character: Int]()
    
    // MARK: Actions

    func setKeyLetterGrouping(_ grouping: [String], twoStrokes: Bool) {
        keyLetterGrouping = [Character: Int]()

        if twoStrokes {
            for letterValue in UnicodeScalar("a").value...UnicodeScalar("z").value {
                keyLetterGrouping[Character(UnicodeScalar(letterValue)!)] = Int(letterValue)
            }
        } else {
            for i in 0 ..< grouping.count {
                for letter in grouping[i] {
                    keyLetterGrouping[letter] = i
                }
            }
        }
    }
    
    private func findNodeToAddWord(_ word: String, node: TrieNode) throws -> TrieNode {
        var node = node
        let wordArray = Array(word)

        // Traverse existing nodes as far as possible.
        var i = 0
        let length = wordArray.count
        while (i < length) {
            let char = wordArray[i]

            guard keyLetterGrouping.keys.contains(char) else {
                throw WordPredictionError.unsupportedWord(invalidChar: char)
            }

            guard let key = keyLetterGrouping[char] else {
                throw WordPredictionError.unsupportedWord(invalidChar: char)
            }

            if let childNode = node.children[key] {
                node = childNode
            } else {
                break
            }
            i += 1
        }

        while (i < length) {
            let char = wordArray[i]

            guard keyLetterGrouping.keys.contains(char) else {
                throw WordPredictionError.unsupportedWord(invalidChar: char)
            }

            guard let key = keyLetterGrouping[char] else {
                throw WordPredictionError.unsupportedWord(invalidChar: char)
            }

            let newNode = TrieNode()
            node.children[key] = newNode
            node = newNode
            i += 1
        }

        return node
    }
    
    private func insert(_ word: String, _ frequency: Int, into node: TrieNode) {
        let wordToInsert = (word, frequency)
        for i in 0 ..< node.words.count {
            let comparedFrequency = node.words[i].1
            let insertFrequency = wordToInsert.1
            
            if insertFrequency >= comparedFrequency {
                node.words.insert(wordToInsert, at: i)
                return
            }
        }
        
        node.words.append(wordToInsert)
    }
    
    func insert(_ word: String, _ frequency: Int) throws {
        guard !word.isEmpty else {
            return
        }
        
        let nodeToAddWord = try findNodeToAddWord(word, node: rootNode)
        insert(word, frequency, into: nodeToAddWord)
        words[word] = frequency
    }
    
    func contains(_ word: String) -> Bool {
        return words[word] != nil
    }
    
    func suggestions(for keyString: [Int]) -> [(String, Int)] {
        var node = rootNode
        
        for i in 0 ..< keyString.count {
            if let nextNode = node.children[keyString[i]] {
                node = nextNode
            } else {
                return []
            }
        }
        
        return node.words
    }
    
    /*
    func getSuggestionsFromLetter(_ keyString: [Int]) -> [(String, Int)] {
        var inputString = ""
        for letterValue in keyString {
            inputString += String(describing: UnicodeScalar(letterValue)!)
        }
        print(inputString)
        return [(inputString, 200), ("dsd", 200), ("ss", 200), ("wwe", 200)]
    }*/

}

class PredictionEngineManager {
    @MainActor static let shared = PredictionEngineManager()

    var engines: [PredictionEngineType: PredictionEngineProtocol] = [:]
    var currentEngineType: PredictionEngineType = .custom

    var currentEngine: PredictionEngineProtocol? {
        return engines[currentEngineType]
    }

    var availableEngines: [PredictionEngineType] {
        return Array(engines.keys)
    }

    private init() {
        // Register default custom engine
        let customEngine = WordPredictionEngine()
        registerEngine(customEngine, for: .custom)

        // Register native engine
        let nativeEngine = NativePredictionEngine()
        registerEngine(nativeEngine, for: .native)
    }

    func registerEngine(_ engine: PredictionEngineProtocol, for type: PredictionEngineType) {
        engines[type] = engine
    }

    @MainActor func switchToEngine(_ type: PredictionEngineType) -> Bool {
        guard engines[type] != nil else {
            return false
        }
        currentEngineType = type
        UserPreferences.shared.predictionEngineType = type.rawValue
        return true
    }

    func setKeyLetterGrouping(_ grouping: [String], twoStrokes: Bool) {
        currentEngine?.setKeyLetterGrouping(grouping, twoStrokes: twoStrokes)
    }

    func insert(_ word: String, _ frequency: Int) throws {
        try currentEngine?.insert(word, frequency)
    }

    func contains(_ word: String) -> Bool {
        return currentEngine?.contains(word) ?? false
    }

    func suggestions(for keyString: [Int]) -> [(String, Int)] {
        return currentEngine?.suggestions(for: keyString) ?? []
    }
}
