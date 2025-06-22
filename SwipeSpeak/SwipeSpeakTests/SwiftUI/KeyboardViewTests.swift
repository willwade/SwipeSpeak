//
//  KeyboardViewTests.swift
//  SwipeSpeakTests
//
//  Created by SwiftUI Migration on 22/06/2025.
//  Copyright © 2025 TeamGleason. All rights reserved.
//

import XCTest
import SwiftUI
@testable import SwipeSpeak

@MainActor
final class KeyboardViewTests: XCTestCase {
    
    var viewModel: KeyboardViewModel!
    
    override func setUpWithError() throws {
        viewModel = KeyboardViewModel()
    }
    
    override func tearDownWithError() throws {
        viewModel = nil
    }
    
    // MARK: - Keyboard Layout Tests
    
    func testKeyboardLayoutConfiguration() throws {
        // Test 4-key layout
        let config4Keys = KeyboardLayoutConfig.config(for: .keys4)
        XCTAssertEqual(config4Keys.layout, .keys4)
        XCTAssertEqual(config4Keys.gridColumns.count, 2)
        XCTAssertEqual(config4Keys.keys.count, 4)
        
        // Test 6-key layout
        let config6Keys = KeyboardLayoutConfig.config(for: .keys6)
        XCTAssertEqual(config6Keys.layout, .keys6)
        XCTAssertEqual(config6Keys.gridColumns.count, 3)
        XCTAssertEqual(config6Keys.keys.count, 6)
        
        // Test 8-key layout
        let config8Keys = KeyboardLayoutConfig.config(for: .keys8)
        XCTAssertEqual(config8Keys.layout, .keys8)
        XCTAssertEqual(config8Keys.gridColumns.count, 4)
        XCTAssertEqual(config8Keys.keys.count, 8)
        
        // Test 2-strokes layout
        let configStrokes = KeyboardLayoutConfig.config(for: .strokes2)
        XCTAssertEqual(configStrokes.layout, .strokes2)
        XCTAssertEqual(configStrokes.gridColumns.count, 3)
        XCTAssertEqual(configStrokes.keys.count, 6)
        
        // Test MSR layout
        let configMSR = KeyboardLayoutConfig.config(for: .msr)
        XCTAssertEqual(configMSR.layout, .msr)
        XCTAssertEqual(configMSR.gridColumns.count, 3)
        XCTAssertEqual(configMSR.keys.count, 6)
    }
    
    func testKeyboardKeyCreation() throws {
        let key = KeyboardKey(
            index: 0,
            text: "ABCDEF",
            letters: "abcdef",
            isSpecial: false,
            textColor: .white,
            backgroundColor: .clear
        )
        
        XCTAssertEqual(key.index, 0)
        XCTAssertEqual(key.text, "ABCDEF")
        XCTAssertEqual(key.letters, "abcdef")
        XCTAssertFalse(key.isSpecial)
        XCTAssertEqual(key.textColor, .white)
        XCTAssertEqual(key.backgroundColor, .clear)
    }
    
    func testMSRKeyCreation() throws {
        let config = KeyboardLayoutConfig.config(for: .msr)
        let msrKeys = config.keys
        
        // Check that MSR keys are created correctly
        XCTAssertEqual(msrKeys.count, 6)
        
        // Check for special keys (Yes/No keys)
        let specialKeys = msrKeys.filter { $0.isSpecial }
        XCTAssertGreaterThan(specialKeys.count, 0, "MSR layout should have special keys")
        
        // Check that special keys have red text color
        for specialKey in specialKeys {
            XCTAssertEqual(specialKey.textColor, .red)
        }
    }
    
    // MARK: - Swipe Direction Tests
    
    func testSwipeDirectionKeyIndex4Keys() throws {
        // Test 4-key layout angle calculations
        let velocity1 = CGSize(width: 100, height: 0) // Right (0°)
        let keyIndex1 = SwipeDirection.keyIndex(for: velocity1, numberOfKeys: 4)
        XCTAssertEqual(keyIndex1, 1)
        
        let velocity2 = CGSize(width: 0, height: 100) // Down (90°)
        let keyIndex2 = SwipeDirection.keyIndex(for: velocity2, numberOfKeys: 4)
        XCTAssertEqual(keyIndex2, 3)
        
        let velocity3 = CGSize(width: -100, height: 0) // Left (180°)
        let keyIndex3 = SwipeDirection.keyIndex(for: velocity3, numberOfKeys: 4)
        XCTAssertEqual(keyIndex3, 2)
        
        let velocity4 = CGSize(width: 0, height: -100) // Up (270°)
        let keyIndex4 = SwipeDirection.keyIndex(for: velocity4, numberOfKeys: 4)
        XCTAssertEqual(keyIndex4, 0)
    }
    
    func testSwipeDirectionKeyIndex6Keys() throws {
        // Test 6-key layout angle calculations
        let velocity1 = CGSize(width: 100, height: 0) // Right (0°)
        let keyIndex1 = SwipeDirection.keyIndex(for: velocity1, numberOfKeys: 6)
        XCTAssertEqual(keyIndex1, 3)
        
        let velocity2 = CGSize(width: 50, height: 86.6) // 60°
        let keyIndex2 = SwipeDirection.keyIndex(for: velocity2, numberOfKeys: 6)
        XCTAssertEqual(keyIndex2, 4)
        
        let velocity3 = CGSize(width: -100, height: 0) // Left (180°)
        let keyIndex3 = SwipeDirection.keyIndex(for: velocity3, numberOfKeys: 6)
        XCTAssertEqual(keyIndex3, 2)
    }
    
    func testSwipeDirectionKeyIndex8Keys() throws {
        // Test 8-key layout angle calculations
        let velocity1 = CGSize(width: 100, height: 0) // Right (0°)
        let keyIndex1 = SwipeDirection.keyIndex(for: velocity1, numberOfKeys: 8)
        XCTAssertEqual(keyIndex1, 3)
        
        let velocity2 = CGSize(width: 70.7, height: 70.7) // 45°
        let keyIndex2 = SwipeDirection.keyIndex(for: velocity2, numberOfKeys: 8)
        XCTAssertEqual(keyIndex2, 4)
        
        let velocity3 = CGSize(width: 0, height: 100) // Down (90°)
        let keyIndex3 = SwipeDirection.keyIndex(for: velocity3, numberOfKeys: 8)
        XCTAssertEqual(keyIndex3, 5)
    }
    
    func testSwipeDirectionTwoStrokesMode() throws {
        // Test two-strokes mode special cases
        let velocity = CGSize(width: 100, height: 0)
        
        // First stroke (-1)
        let keyIndex1 = SwipeDirection.keyIndex(for: velocity, numberOfKeys: -1)
        XCTAssertEqual(keyIndex1, 3)
        
        // Second stroke (-2)
        let keyIndex2 = SwipeDirection.keyIndex(for: velocity, numberOfKeys: -2)
        XCTAssertEqual(keyIndex2, 0)
        
        // Second stroke with Y,Z (-3)
        let keyIndex3 = SwipeDirection.keyIndex(for: velocity, numberOfKeys: -3)
        XCTAssertEqual(keyIndex3, 0)
    }
    
    func testSwipeDirectionDetection() throws {
        // Test simple direction detection
        let rightVelocity = CGSize(width: 100, height: 10)
        let rightDirection = SwipeDirection.direction(for: rightVelocity)
        XCTAssertEqual(rightDirection, .right)
        
        let leftVelocity = CGSize(width: -100, height: 10)
        let leftDirection = SwipeDirection.direction(for: leftVelocity)
        XCTAssertEqual(leftDirection, .left)
        
        let upVelocity = CGSize(width: 10, height: -100)
        let upDirection = SwipeDirection.direction(for: upVelocity)
        XCTAssertEqual(upDirection, .up)
        
        let downVelocity = CGSize(width: 10, height: 100)
        let downDirection = SwipeDirection.direction(for: downVelocity)
        XCTAssertEqual(downDirection, .down)
    }
    
    // MARK: - Keyboard View Model Tests
    
    func testKeyboardViewModelInitialization() throws {
        XCTAssertEqual(viewModel.keyboardLayout, UserPreferences.shared.keyboardLayout)
        XCTAssertEqual(viewModel.currentWord, "")
        XCTAssertTrue(viewModel.enteredKeys.isEmpty)
        XCTAssertTrue(viewModel.predictions.isEmpty)
        XCTAssertFalse(viewModel.isLoadingPredictions)
        XCTAssertNil(viewModel.firstStroke)
        XCTAssertEqual(viewModel.msrKeyboardState, .master)
    }
    
    func testKeyEntryHandling() throws {
        // Test regular key entry
        viewModel.keyEntered(0, isSwipe: false)
        XCTAssertEqual(viewModel.enteredKeys.count, 1)
        XCTAssertEqual(viewModel.enteredKeys.first, 0)
        
        // Test swipe key entry
        viewModel.keyEntered(1, isSwipe: true)
        XCTAssertEqual(viewModel.enteredKeys.count, 2)
        XCTAssertEqual(viewModel.enteredKeys.last, 1)
    }
    
    func testTwoStrokeHandling() throws {
        // Set two-stroke mode
        viewModel.isTwoStrokesMode = true
        
        // Test first stroke
        XCTAssertNil(viewModel.firstStroke)
        viewModel.firstStrokeEntered(key: 2, isSwipe: false)
        XCTAssertEqual(viewModel.firstStroke, 2)
        
        // Test second stroke
        viewModel.secondStrokeEntered(key: 3, isSwipe: false)
        XCTAssertNil(viewModel.firstStroke) // Should be reset
        XCTAssertEqual(viewModel.enteredKeys.count, 1)
        XCTAssertEqual(viewModel.enteredKeys.first, 3)
    }
    
    func testMSRKeyHandling() throws {
        // Test MSR key entry
        viewModel.msrKeyEntered(key: 1, isSwipe: false)
        XCTAssertEqual(viewModel.enteredKeys.count, 1)
        XCTAssertEqual(viewModel.enteredKeys.first, 1)
    }
    
    // MARK: - Performance Tests
    
    func testKeyboardLayoutSwitchingPerformance() throws {
        measure {
            for layout in [KeyboardLayout.keys4, .keys6, .keys8, .strokes2, .msr] {
                _ = KeyboardLayoutConfig.config(for: layout)
            }
        }
    }
    
    func testSwipeDirectionCalculationPerformance() throws {
        let velocities = [
            CGSize(width: 100, height: 0),
            CGSize(width: 0, height: 100),
            CGSize(width: -100, height: 0),
            CGSize(width: 0, height: -100),
            CGSize(width: 70.7, height: 70.7),
            CGSize(width: -70.7, height: 70.7),
            CGSize(width: -70.7, height: -70.7),
            CGSize(width: 70.7, height: -70.7)
        ]
        
        measure {
            for velocity in velocities {
                for numberOfKeys in [4, 6, 8, -1, -2, -3] {
                    _ = SwipeDirection.keyIndex(for: velocity, numberOfKeys: numberOfKeys)
                }
            }
        }
    }
}
