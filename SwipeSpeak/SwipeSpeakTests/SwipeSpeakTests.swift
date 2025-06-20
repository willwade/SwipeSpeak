//
//  SwipeSpeakTests.swift
//  SwipeSpeakTests
//
//  Created by Testing Implementation on 20/06/2025.
//  Copyright © 2025 TeamGleason. All rights reserved.
//

import XCTest
@testable import SwipeSpeak

final class SwipeSpeakTests: XCTestCase {

    override func setUpWithError() throws {
        // Reset UserPreferences to default state for each test
        UserPreferences.shared.predictionEngineType = PredictionEngineType.custom.rawValue
    }

    override func tearDownWithError() throws {
        // Clean up after each test
    }

    // MARK: - Basic App Functionality Tests

    func testAppDelegateExists() throws {
        let appDelegate = AppDelegate()
        XCTAssertNotNil(appDelegate)
    }

    func testUserPreferencesSharedInstance() throws {
        let prefs1 = UserPreferences.shared
        let prefs2 = UserPreferences.shared
        XCTAssertTrue(prefs1 === prefs2, "UserPreferences should be a singleton")
    }

    func testPredictionEngineManagerSharedInstance() throws {
        let manager1 = PredictionEngineManager.shared
        let manager2 = PredictionEngineManager.shared
        XCTAssertTrue(manager1 === manager2, "PredictionEngineManager should be a singleton")
    }
}
