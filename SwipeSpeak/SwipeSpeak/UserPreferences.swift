//
//  UserPreferences.swift
//  SwipeSpeak
//
//  Created by Daniel Tsirulnikov on 06/11/2017.
//  Updated by Daniel Tsirulnikov on 11/9/17.
//  Copyright © 2017 TeamGleason. All rights reserved.
//

import Foundation
import AVFoundation
import Combine
import CloudKit

enum KeyboardLayout: Int {
    case keys4 = 4
    case keys6 = 6
    case keys8 = 8
    case strokes2 = -1
    case msr = 37

    static let `default` = KeyboardLayout.keys6
    
    func localizedString() -> String {
        switch self {
        case .keys4:
            return LocalizedStrings.Keyboard.fourKeys
        case .keys6:
            return LocalizedStrings.Keyboard.sixKeys
        case .keys8:
            return LocalizedStrings.Keyboard.eightKeys
        case .strokes2:
            return LocalizedStrings.Keyboard.twoStrokes
        case .msr:
            return LocalizedStrings.Keyboard.msr
        }
    }

    var displayName: String {
        return localizedString()
    }
}

/// MSR Keyboard State
enum MSRKeyboardState: Equatable {
    case master
    case detail(keyIndex: Int)
}

struct WordKeys {
    static let word = "sentence"
    static let frequency = "freq"
    static let date = "date"
}

struct SentenceKeys {
    static let sentence = "sentence"
    static let date     = "date"
}

extension NSNotification.Name {
    static let KeyboardLayoutDidChange = NSNotification.Name(rawValue: "KeyboardLayoutDidChange")
    static let UserAddedWordsUpdated = NSNotification.Name(rawValue: "UserAddedWordsUpdated")
}

struct Keys {
    
    static let keyboardLayout = "keyboardLayout"

    static let announceLettersCount      = "announceLettersCount"
    static let vibrate                   = "vibrate"
    static let longerPauseBetweenLetters = "longerPauseBetweenLetters"

    static let audioFeedback    = "audioFeedback"
    static let voiceIdentifier  = "voiceIdentifier"
    static let speechRate       = "speechRate"
    static let speechVolume     = "speechVolume"
    
    static let enableCloudSync  = "enableCloudSync"

    static let predictionEngineType = "predictionEngineType"

    static let userAddedWords = "userAddedWords"
    static let userWordRating = "wordFrequencies"

    static let sentenceHistory  = "sentenceHistory"
    
    static func iCloudSyncKeys() -> [String] {
        return [
            Keys.keyboardLayout,
            
            Keys.announceLettersCount,
            Keys.vibrate,
            Keys.longerPauseBetweenLetters,
            
            Keys.audioFeedback,
            Keys.voiceIdentifier,
            Keys.speechRate,
            Keys.speechVolume,

            //Keys.enableCloudSync,
            Keys.predictionEngineType,

            Keys.userAddedWords,
            Keys.userWordRating,
            Keys.sentenceHistory,
        ]
    }
    
}

@MainActor
class UserPreferences: ObservableObject {

    // MARK: Shared Instance

    static let shared = UserPreferences()

    // MARK: User Defaults

    private var userDefaults: UserDefaults {
        return UserDefaults.standard
    }

    // MARK: Initialization

    private init() {
        userDefaults.register(defaults: [
            Keys.keyboardLayout: KeyboardLayout.default.rawValue,

            Keys.announceLettersCount: true,
            Keys.vibrate: false,
            Keys.longerPauseBetweenLetters: true,

            Keys.audioFeedback: true,
            Keys.speechRate: AVSpeechUtteranceDefaultSpeechRate,
            Keys.speechVolume: 1.0,

            Keys.enableCloudSync: false, // Temporarily disabled to fix concurrency crash
            Keys.predictionEngineType: "native",
            ])

        // Initialize @Published properties from UserDefaults after defaults are registered
        let savedLayout = userDefaults.integer(forKey: Keys.keyboardLayout)
        self.keyboardLayout = KeyboardLayout(rawValue: savedLayout) ?? KeyboardLayout.default
        self.enableCloudSync = userDefaults.bool(forKey: Keys.enableCloudSync)

        // Enable CloudKit sync if enabled (but only if CloudKit is available)
        if self.enableCloudSync {
            #if targetEnvironment(simulator)
            // Disable CloudKit sync in simulator to prevent crashes
            print("CloudKit sync disabled in simulator")
            self.enableCloudSync = false
            #else
            enableCloudKitSync()
            #endif
        }
    }

    // MARK: CloudKit Sync

    private func enableCloudKitSync() {
        // Check if CloudKit is available before enabling sync
        if CloudKitSyncManager.shared.isCloudAvailable {
            CloudKitSyncManager.shared.startMonitoring(keys: Keys.iCloudSyncKeys())

            // Fetch existing preferences from CloudKit
            Task {
                await CloudKitSyncManager.shared.fetchUserPreferences()
            }
        } else {
            print("CloudKit not available, sync disabled")
            // Automatically disable cloud sync if CloudKit is not available
            DispatchQueue.main.async {
                self.enableCloudSync = false
            }
        }
    }

    private func disableCloudKitSync() {
        CloudKitSyncManager.shared.stopMonitoring()
    }
    
    // MARK: Properties
    
    @Published var keyboardLayout: KeyboardLayout = .default {
        didSet {
            userDefaults.set(keyboardLayout.rawValue, forKey: Keys.keyboardLayout)
            // Keep NotificationCenter for backward compatibility during migration
            NotificationCenter.default.post(name: Notification.Name.KeyboardLayoutDidChange, object: self)
        }
    }
    
    var announceLettersCount: Bool {
        get {
            return userDefaults.bool(forKey: Keys.announceLettersCount)
        }
        set(newValue) {
            userDefaults.set(newValue, forKey: Keys.announceLettersCount)
        }
    }
    
    var vibrate: Bool {
        get {
            return userDefaults.bool(forKey: Keys.vibrate)
        }
        set(newValue) {
            userDefaults.set(newValue, forKey: Keys.vibrate)
        }
    }
    
    var longerPauseBetweenLetters: Bool {
        get {
            return userDefaults.bool(forKey: Keys.longerPauseBetweenLetters)
        }
        set(newValue) {
            userDefaults.set(newValue, forKey: Keys.longerPauseBetweenLetters)
        }
    }
    
    var audioFeedback: Bool {
        get {
            return userDefaults.bool(forKey: Keys.audioFeedback)
        }
        set(newValue) {
            userDefaults.set(newValue, forKey: Keys.audioFeedback)
        }
    }
    
    var voiceIdentifier: String? {
        get {
            return userDefaults.string(forKey: Keys.voiceIdentifier)
        }
        set(newValue) {
            userDefaults.set(newValue, forKey: Keys.voiceIdentifier)
        }
    }
    
    var speechRate: Float {
        get {
            return userDefaults.float(forKey: Keys.speechRate)
        }
        set(newValue) {
            userDefaults.set(newValue, forKey: Keys.speechRate)
        }
    }
    
    var speechVolume: Float {
        get {
            return userDefaults.float(forKey: Keys.speechVolume)
        }
        set(newValue) {
            userDefaults.set(newValue, forKey: Keys.speechVolume)
        }
    }
    
    @Published var enableCloudSync: Bool = false {
        didSet {
            userDefaults.set(enableCloudSync, forKey: Keys.enableCloudSync)

            #if targetEnvironment(simulator)
            // Prevent CloudKit sync in simulator
            if enableCloudSync {
                print("CloudKit sync not supported in simulator")
                enableCloudSync = false
                return
            }
            #endif

            if enableCloudSync {
                enableCloudKitSync()
            } else {
                disableCloudKitSync()
            }
        }
    }

    var predictionEngineType: String? {
        get {
            return userDefaults.string(forKey: Keys.predictionEngineType)
        }
        set(newValue) {
            userDefaults.set(newValue, forKey: Keys.predictionEngineType)
        }
    }
    
    // MARK: User added words
    
    var userAddedWords: [String] {
        get {
            guard let array = userDefaults.array(forKey: Keys.userAddedWords) as? [String] else { return [] }
            return array
        }
        set(newValue) {
            userDefaults.set(newValue, forKey: Keys.userAddedWords)
        }
    }
    
    private let MaxUserAddedWords = 1000
    
    func addWord(_ word: String) {
        let array = userAddedWords
        var newArray = Array(array)
        newArray.insert(word, at: 0)
        
        if newArray.count > MaxUserAddedWords {
            newArray.removeLast()
        }
        
        userAddedWords = newArray
    }
    
    func removeWord(_ index: Int) {
        let array = userAddedWords
        guard index < array.count else { return }
        
        var newArray = Array(array)
        newArray.remove(at: index)
        
        userAddedWords = newArray
    }
    
    func clearWords() {
        userAddedWords = []
    }

    /// Validates if a word is valid for adding to the user dictionary
    /// - Parameter word: The word to validate
    /// - Returns: True if the word is valid (no spaces, punctuation, and not empty)
    func isWordValid(_ word: String) -> Bool {
        let trimmed = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }

        // Check for spaces or punctuation
        let allowedCharacters = CharacterSet.letters
        return trimmed.rangeOfCharacter(from: allowedCharacters.inverted) == nil
    }
    
    // MARK: Word Frequencies

    var userWordRating: [String: Int] {
        get {
            guard let dict = userDefaults.dictionary(forKey: Keys.userWordRating) as? [String: Int] else { return [:] }
            return dict
        }
        set(newValue) {
            userDefaults.set(newValue, forKey: Keys.userWordRating)
        }
    }
    
    private let MaxWordFrequencies = 1000
    
    func incrementWordRating(_ word: String) {
        guard !word.isEmpty else {
            return
        }
        
        var wordRatings = self.userWordRating
        
        let wordRating = wordRatings[word] ?? 0
        wordRatings[word] = wordRating + 1

        self.userWordRating = wordRatings
    }
    
    func clearWordRating() {
        userWordRating = [:]
    }
    
    /*
    /// Array of dictionaries containing the word, frequency and date
    var userAddedWords: [[String: Any]] {
        get {
            guard let array = userDefaults.array(forKey: Keys.userAddedWords) as? [[String: Any]] else { return [] }
            return array
        }
        set(newValue) {
            userDefaults.set(newValue, forKey: Keys.userAddedWords)
        }
    }
    
    var userAddedWordsArray: [String] {
        guard let array = userDefaults.array(forKey: Keys.userAddedWords) as? [[String: Any]] else { return [] }
        return array.map { $0[WordKeys.word] as! String }
    }
    
    private let MaxUserAddedWords = 100
    
    func addWord(_ word: String) {
        let trimmedWord = word.trimmingCharacters(in: .whitespacesAndNewlines)

        var array = Array(userAddedWords)
        
        let dict = [WordKeys.word: trimmedWord,
                    WordKeys.frequency: Constants.defaultWordFrequency,
                    SentenceKeys.date: Date()] as [String : Any]
        array.insert(dict, at: 0)
        
        if array.count > MaxUserAddedWords {
            array.removeLast()
        }
        
        userAddedWords = array
        
        NotificationCenter.default.post(name: Notification.Name.UserAddedWordsUpdated, object: self, userInfo: [WordKeys.word: trimmedWord, WordKeys.frequency: Constants.defaultWordFrequency])
    }
    
    func removeWord(_ index: Int) {
        var array = Array(userAddedWords)
        guard index < array.count else { return }
        
        array.remove(at: index)
        
        userAddedWords = array
    }
    */

//    private func importLegacyWordsIfNeeded() {
//        // Previously we were storing words in an array without frequencies
//        guard let legacyWords = userDefaults.array(forKey: Keys.userAddedWordsLegacy) as? [String] else { return }
//
//        for legacyWord in legacyWords {
//            addWord(legacyWord)
//        }
//
//        userDefaults.removeObject(forKey: Keys.userAddedWordsLegacy)
//    }
//
    // MARK: Sentence history

    var sentenceHistory: [[String: Any]] {
        get {
            guard let array = userDefaults.array(forKey: Keys.sentenceHistory) as? [[String: Any]] else { return [] }
            return array
        }
        set(newValue) {
            userDefaults.set(newValue, forKey: Keys.sentenceHistory)
        }
    }
    
    private let MaxSentenceHistory = 100

    func addSentence(_ sentence: String) {
        let trimmedSentence = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
        
        var array = Array(sentenceHistory)
        
        let dict = [SentenceKeys.sentence: trimmedSentence,
                    SentenceKeys.date: Date()] as [String : Any]
        array.insert(dict, at: 0)
        
        if array.count > MaxSentenceHistory {
            array.removeLast()
        }
        
        sentenceHistory = array
    }
    
    func removeSentence(_ index: Int) {
        var array = Array(sentenceHistory)
        guard index < array.count else { return }
        
        array.remove(at: index)
        
        sentenceHistory = array
    }
    
    func clearSentenceHistory() {
        sentenceHistory = []
    }
    
}
