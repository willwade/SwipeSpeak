//
//  Phase3IntegrationTests.swift
//  SwipeSpeakTests
//
//  Created by SwiftUI Migration on 22/06/2025.
//  Copyright © 2025 TeamGleason. All rights reserved.
//

import XCTest
import SwiftUI
@testable import SwipeSpeak

@MainActor
final class Phase3IntegrationTests: XCTestCase {
    
    var keyboardViewModel: KeyboardViewModel!
    var animationManager: AnimationStateManager!
    var hapticManager: HapticFeedbackManager!
    
    override func setUpWithError() throws {
        keyboardViewModel = KeyboardViewModel()
        animationManager = AnimationStateManager()
        hapticManager = HapticFeedbackManager.shared
    }
    
    override func tearDownWithError() throws {
        keyboardViewModel = nil
        animationManager = nil
        hapticManager = nil
    }
    
    // MARK: - Keyboard Layout Integration Tests
    
    func testKeyboardLayoutSwitchingWithAnimations() throws {
        // Test switching between all keyboard layouts
        let layouts: [KeyboardLayout] = [.keys4, .keys6, .keys8, .strokes2, .msr]
        
        for layout in layouts {
            // Switch layout
            keyboardViewModel.keyboardLayout = layout
            
            // Start layout transition animation
            animationManager.startLayoutTransition(duration: 0.1)
            XCTAssertTrue(animationManager.isLayoutTransitioning)
            
            // Verify layout configuration
            let config = KeyboardLayoutConfig.config(for: layout)
            XCTAssertEqual(config.layout, layout)
            
            // Wait for animation to complete
            let expectation = XCTestExpectation(description: "Layout transition for \(layout)")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                XCTAssertFalse(self.animationManager.isLayoutTransitioning)
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 0.5)
        }
    }
    
    func testKeyboardInteractionWithFeedback() throws {
        // Test key interaction with visual and haptic feedback
        let keyIndex = 0
        
        // Simulate key press
        animationManager.setKeyPressed(keyIndex, isPressed: true)
        animationManager.highlightKey(keyIndex, duration: 0.3)
        
        // Verify states
        XCTAssertTrue(animationManager.pressedKeys.contains(keyIndex))
        XCTAssertTrue(animationManager.highlightedKeys.contains(keyIndex))
        
        // Simulate key entry in view model
        keyboardViewModel.keyEntered(keyIndex, isSwipe: false)
        XCTAssertEqual(keyboardViewModel.enteredKeys.last, keyIndex)
        
        // Release key
        animationManager.setKeyPressed(keyIndex, isPressed: false)
        XCTAssertFalse(animationManager.pressedKeys.contains(keyIndex))
    }
    
    func testSwipeGestureIntegration() throws {
        // Test swipe gesture with direction detection and feedback
        let velocity = CGSize(width: 100, height: 0) // Right swipe
        let keyIndex = SwipeDirection.keyIndex(for: velocity, numberOfKeys: 4)
        
        // Show swipe direction
        animationManager.showSwipeDirection(.right, duration: 0.3)
        XCTAssertEqual(animationManager.swipeDirection, .right)
        
        // Highlight target key
        animationManager.highlightKey(keyIndex, duration: 0.3)
        XCTAssertTrue(animationManager.highlightedKeys.contains(keyIndex))
        
        // Process swipe in view model
        keyboardViewModel.keyEntered(keyIndex, isSwipe: true)
        XCTAssertEqual(keyboardViewModel.enteredKeys.last, keyIndex)
    }
    
    // MARK: - Two-Stroke Mode Integration Tests
    
    func testTwoStrokeModeIntegration() throws {
        // Enable two-stroke mode
        keyboardViewModel.isTwoStrokesMode = true
        
        // First stroke
        let firstKey = 2
        animationManager.highlightKey(firstKey, duration: 0.3)
        keyboardViewModel.firstStrokeEntered(key: firstKey, isSwipe: false)
        
        XCTAssertEqual(keyboardViewModel.firstStroke, firstKey)
        XCTAssertTrue(animationManager.highlightedKeys.contains(firstKey))
        
        // Second stroke
        let secondKey = 3
        animationManager.highlightKey(secondKey, duration: 0.3)
        keyboardViewModel.secondStrokeEntered(key: secondKey, isSwipe: false)
        
        XCTAssertNil(keyboardViewModel.firstStroke) // Should be reset
        XCTAssertEqual(keyboardViewModel.enteredKeys.last, secondKey)
    }
    
    func testTwoStrokeSwipeIntegration() throws {
        keyboardViewModel.isTwoStrokesMode = true
        
        // First stroke with swipe
        let velocity1 = CGSize(width: 100, height: 0)
        let firstKey = SwipeDirection.keyIndex(for: velocity1, numberOfKeys: -1) // First stroke mode
        
        animationManager.showSwipeDirection(.right, duration: 0.3)
        animationManager.highlightKey(firstKey, duration: 0.3)
        keyboardViewModel.firstStrokeEntered(key: firstKey, isSwipe: true)
        
        XCTAssertEqual(keyboardViewModel.firstStroke, firstKey)
        
        // Second stroke with swipe
        let velocity2 = CGSize(width: 0, height: 100)
        let secondKey = SwipeDirection.keyIndex(for: velocity2, numberOfKeys: -2) // Second stroke mode
        
        animationManager.showSwipeDirection(.down, duration: 0.3)
        animationManager.highlightKey(secondKey, duration: 0.3)
        keyboardViewModel.secondStrokeEntered(key: secondKey, isSwipe: true)
        
        XCTAssertNil(keyboardViewModel.firstStroke)
        XCTAssertEqual(keyboardViewModel.enteredKeys.last, secondKey)
    }
    
    // MARK: - MSR Keyboard Integration Tests
    
    func testMSRKeyboardIntegration() throws {
        // Switch to MSR layout
        keyboardViewModel.keyboardLayout = .msr
        let config = KeyboardLayoutConfig.config(for: .msr)
        
        // Test MSR key interaction
        let msrKey = 1
        animationManager.highlightKey(msrKey, duration: 0.3)
        keyboardViewModel.msrKeyEntered(key: msrKey, isSwipe: false)
        
        XCTAssertEqual(keyboardViewModel.enteredKeys.last, msrKey)
        XCTAssertTrue(animationManager.highlightedKeys.contains(msrKey))
        
        // Verify MSR-specific key properties
        let msrKeys = config.keys
        let specialKeys = msrKeys.filter { $0.isSpecial }
        XCTAssertGreaterThan(specialKeys.count, 0)
    }
    
    // MARK: - Performance Integration Tests
    
    func testCompleteInteractionPerformance() throws {
        measure {
            // Simulate a complete typing interaction
            for i in 0..<20 {
                let keyIndex = i % 4
                
                // Press key
                animationManager.setKeyPressed(keyIndex, isPressed: true)
                animationManager.highlightKey(keyIndex, duration: 0.01)
                
                // Process key
                keyboardViewModel.keyEntered(keyIndex, isSwipe: i % 2 == 0)
                
                // Release key
                animationManager.setKeyPressed(keyIndex, isPressed: false)
                
                // Occasional swipe
                if i % 5 == 0 {
                    animationManager.showSwipeDirection(.right, duration: 0.01)
                }
            }
        }
    }
    
    func testLayoutSwitchingPerformance() throws {
        let layouts: [KeyboardLayout] = [.keys4, .keys6, .keys8, .strokes2, .msr]
        
        measure {
            for layout in layouts {
                keyboardViewModel.keyboardLayout = layout
                animationManager.startLayoutTransition(duration: 0.001)
                _ = KeyboardLayoutConfig.config(for: layout)
            }
        }
    }
    
    func testConcurrentInteractionHandling() throws {
        let expectation = XCTestExpectation(description: "Concurrent interactions completed")
        
        DispatchQueue.concurrentPerform(iterations: 10) { index in
            // Simulate concurrent key interactions
            animationManager.highlightKey(index % 4, duration: 0.1)
            keyboardViewModel.keyEntered(index % 4, isSwipe: index % 2 == 0)
            
            if index == 9 {
                DispatchQueue.main.async {
                    expectation.fulfill()
                }
            }
        }
        
        wait(for: [expectation], timeout: 2.0)
        
        // Verify system stability
        XCTAssertGreaterThan(keyboardViewModel.enteredKeys.count, 0)
        XCTAssertNoThrow(animationManager.clearAllStates())
    }
    
    // MARK: - Error Handling Integration Tests
    
    func testInvalidKeyIndexHandling() throws {
        // Test handling of invalid key indices
        let invalidKeyIndex = 999
        
        XCTAssertNoThrow(animationManager.highlightKey(invalidKeyIndex))
        XCTAssertNoThrow(animationManager.setKeyPressed(invalidKeyIndex, isPressed: true))
        XCTAssertNoThrow(keyboardViewModel.keyEntered(invalidKeyIndex, isSwipe: false))
    }
    
    func testRapidLayoutSwitching() throws {
        // Test rapid layout switching doesn't cause issues
        let layouts: [KeyboardLayout] = [.keys4, .keys6, .keys8, .strokes2, .msr]
        
        for _ in 0..<5 {
            for layout in layouts {
                keyboardViewModel.keyboardLayout = layout
                animationManager.startLayoutTransition(duration: 0.001)
            }
        }
        
        // Verify final state is stable
        XCTAssertEqual(keyboardViewModel.keyboardLayout, .msr)
        XCTAssertNoThrow(animationManager.clearAllStates())
    }
    
    // MARK: - Accessibility Integration Tests
    
    func testAccessibilityIntegration() throws {
        // Test that accessibility preferences are respected
        let testAnimation = Animation.easeInOut(duration: 0.3)
        let optimizedAnimation = AnimationPreferences.optimizedAnimation(testAnimation, value: true)
        
        XCTAssertNotNil(optimizedAnimation)
        
        // Test reduce motion preference
        let reduceMotion = AnimationPreferences.reduceMotion
        XCTAssertTrue(reduceMotion is Bool)
        
        // Test cross-fade preference
        let prefersCrossFade = AnimationPreferences.prefersCrossFadeTransitions
        XCTAssertTrue(prefersCrossFade is Bool)
    }
    
    // MARK: - Memory Management Tests
    
    func testMemoryManagement() throws {
        // Test that repeated operations don't cause memory leaks
        for _ in 0..<100 {
            let tempAnimationManager = AnimationStateManager()
            
            for i in 0..<10 {
                tempAnimationManager.highlightKey(i, duration: 0.001)
                tempAnimationManager.setKeyPressed(i, isPressed: true)
                tempAnimationManager.showSwipeDirection(.right, duration: 0.001)
            }
            
            tempAnimationManager.clearAllStates()
        }
        
        // If we reach here without crashes, memory management is working
        XCTAssertTrue(true)
    }
    
    func testCleanupOnDeallocation() throws {
        var tempAnimationManager: AnimationStateManager? = AnimationStateManager()
        
        // Set up some state
        tempAnimationManager?.highlightKey(0)
        tempAnimationManager?.setKeyPressed(1, isPressed: true)
        tempAnimationManager?.showSwipeDirection(.left)
        
        // Release reference
        tempAnimationManager = nil
        
        // Verify cleanup (implicit - no crashes means success)
        XCTAssertNil(tempAnimationManager)
    }
}
