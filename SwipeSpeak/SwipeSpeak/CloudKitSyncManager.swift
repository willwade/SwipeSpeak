//
//  CloudKitSyncManager.swift
//  SwipeSpeak
//
//  Created by SwiftUI Migration on 22/06/2025.
//  Copyright © 2025 TeamGleason. All rights reserved.
//

import Foundation
import CloudKit
import Combine

/// CloudKit sync status
enum CloudKitSyncStatus {
    case idle
    case syncing
    case success
    case error(String)
}

/// Modern CloudKit sync manager to replace Zephyr
@MainActor
class CloudKitSyncManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var syncStatus: CloudKitSyncStatus = .idle
    @Published var lastSyncDate: Date?
    @Published var isCloudAvailable: Bool = false
    
    // MARK: - Private Properties

    private let container: CKContainer?
    private let database: CKDatabase?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Singleton

    static let shared = CloudKitSyncManager()

    // MARK: - Initialization

    private init() {
        // Safely initialize CloudKit container
        self.container = CKContainer.default()
        self.database = container?.privateCloudDatabase

        if container != nil {
            print("CloudKit container initialized successfully")
            checkCloudKitAvailability()
        } else {
            print("Failed to initialize CloudKit container")
            isCloudAvailable = false
        }
    }
    
    // MARK: - Public Methods
    
    /// Start monitoring keys for sync
    func startMonitoring(keys: [String]) {
        guard isCloudAvailable else {
            print("CloudKit not available, skipping monitoring")
            return
        }
        
        // Monitor UserDefaults changes for the specified keys
        for _ in keys {
            NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
                .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
                .sink { [weak self] _ in
                    Task {
                        await self?.syncUserPreferences()
                    }
                }
                .store(in: &cancellables)
        }
    }
    
    /// Stop monitoring keys
    func stopMonitoring() {
        cancellables.removeAll()
    }
    
    /// Manually trigger sync
    func syncNow() async {
        await syncUserPreferences()
    }
    
    // MARK: - Private Methods
    
    private func checkCloudKitAvailability() {
        guard let container = container else {
            isCloudAvailable = false
            print("CloudKit container not available")
            return
        }

        Task {
            do {
                let status = try await container.accountStatus()
                await MainActor.run {
                    self.isCloudAvailable = status == .available
                }
            } catch {
                await MainActor.run {
                    self.isCloudAvailable = false
                    print("CloudKit availability check failed: \(error)")
                }
            }
        }
    }
    
    private func syncUserPreferences() async {
        guard isCloudAvailable, let database = database else {
            print("CloudKit not available or database not initialized")
            return
        }

        await MainActor.run {
            syncStatus = .syncing
        }

        do {
            // Create or update user preferences record
            let record = try await createUserPreferencesRecord()
            let savedRecord = try await database.save(record)

            await MainActor.run {
                self.syncStatus = .success
                self.lastSyncDate = Date()
                print("CloudKit sync successful: \(savedRecord.recordID)")
            }
        } catch {
            await MainActor.run {
                self.syncStatus = .error(error.localizedDescription)
                print("CloudKit sync failed: \(error)")
            }
        }
    }
    
    private func createUserPreferencesRecord() async throws -> CKRecord {
        let recordID = CKRecord.ID(recordName: "UserPreferences")
        let record = CKRecord(recordType: "UserPreferences", recordID: recordID)
        
        let userDefaults = UserDefaults.standard
        
        // Sync all the keys that were previously synced by Zephyr
        record["keyboardLayout"] = userDefaults.integer(forKey: Keys.keyboardLayout)
        record["announceLettersCount"] = userDefaults.bool(forKey: Keys.announceLettersCount)
        record["vibrate"] = userDefaults.bool(forKey: Keys.vibrate)
        record["longerPauseBetweenLetters"] = userDefaults.bool(forKey: Keys.longerPauseBetweenLetters)
        record["audioFeedback"] = userDefaults.bool(forKey: Keys.audioFeedback)
        record["speechRate"] = userDefaults.float(forKey: Keys.speechRate)
        record["speechVolume"] = userDefaults.float(forKey: Keys.speechVolume)
        record["predictionEngineType"] = userDefaults.string(forKey: Keys.predictionEngineType)
        
        if let voiceIdentifier = userDefaults.string(forKey: Keys.voiceIdentifier) {
            record["voiceIdentifier"] = voiceIdentifier
        }
        
        // Sync custom words and ratings
        if let userAddedWords = userDefaults.array(forKey: Keys.userAddedWords) as? [String] {
            record["userAddedWords"] = userAddedWords
        }
        
        if let userWordRating = userDefaults.dictionary(forKey: Keys.userWordRating) {
            // Convert dictionary to JSON string for CloudKit storage
            if let jsonData = try? JSONSerialization.data(withJSONObject: userWordRating),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                record["userWordRating"] = jsonString
            }
        }
        
        if let sentenceHistory = userDefaults.array(forKey: Keys.sentenceHistory) as? [String] {
            record["sentenceHistory"] = sentenceHistory
        }
        
        return record
    }
    
    /// Fetch and apply user preferences from CloudKit
    func fetchUserPreferences() async {
        guard isCloudAvailable, let database = database else {
            print("CloudKit not available or database not initialized")
            return
        }

        do {
            let recordID = CKRecord.ID(recordName: "UserPreferences")
            let record = try await database.record(for: recordID)

            await MainActor.run {
                self.applyUserPreferences(from: record)
            }
        } catch {
            print("Failed to fetch user preferences from CloudKit: \(error)")
        }
    }
    
    private func applyUserPreferences(from record: CKRecord) {
        let userDefaults = UserDefaults.standard
        
        if let keyboardLayout = record["keyboardLayout"] as? Int {
            userDefaults.set(keyboardLayout, forKey: Keys.keyboardLayout)
        }
        
        if let announceLettersCount = record["announceLettersCount"] as? Bool {
            userDefaults.set(announceLettersCount, forKey: Keys.announceLettersCount)
        }
        
        if let vibrate = record["vibrate"] as? Bool {
            userDefaults.set(vibrate, forKey: Keys.vibrate)
        }
        
        if let longerPauseBetweenLetters = record["longerPauseBetweenLetters"] as? Bool {
            userDefaults.set(longerPauseBetweenLetters, forKey: Keys.longerPauseBetweenLetters)
        }
        
        if let audioFeedback = record["audioFeedback"] as? Bool {
            userDefaults.set(audioFeedback, forKey: Keys.audioFeedback)
        }
        
        if let speechRate = record["speechRate"] as? Float {
            userDefaults.set(speechRate, forKey: Keys.speechRate)
        }
        
        if let speechVolume = record["speechVolume"] as? Float {
            userDefaults.set(speechVolume, forKey: Keys.speechVolume)
        }
        
        if let predictionEngineType = record["predictionEngineType"] as? String {
            userDefaults.set(predictionEngineType, forKey: Keys.predictionEngineType)
        }
        
        if let voiceIdentifier = record["voiceIdentifier"] as? String {
            userDefaults.set(voiceIdentifier, forKey: Keys.voiceIdentifier)
        }
        
        if let userAddedWords = record["userAddedWords"] as? [String] {
            userDefaults.set(userAddedWords, forKey: Keys.userAddedWords)
        }
        
        if let userWordRatingJSON = record["userWordRating"] as? String,
           let jsonData = userWordRatingJSON.data(using: .utf8),
           let userWordRating = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
            userDefaults.set(userWordRating, forKey: Keys.userWordRating)
        }
        
        if let sentenceHistory = record["sentenceHistory"] as? [String] {
            userDefaults.set(sentenceHistory, forKey: Keys.sentenceHistory)
        }
        
        print("Applied user preferences from CloudKit")
    }
}
