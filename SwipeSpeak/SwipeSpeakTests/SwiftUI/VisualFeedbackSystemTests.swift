//
//  VisualFeedbackSystemTests.swift
//  SwipeSpeakTests
//
//  Created by SwiftUI Migration on 22/06/2025.
//  Copyright © 2025 TeamGleason. All rights reserved.
//

import XCTest
import SwiftUI
@testable import SwipeSpeak

@MainActor
final class VisualFeedbackSystemTests: XCTestCase {
    
    var hapticManager: HapticFeedbackManager!
    var animationManager: AnimationStateManager!
    var performanceMonitor: AnimationPerformanceMonitor!
    
    override func setUpWithError() throws {
        hapticManager = HapticFeedbackManager.shared
        animationManager = AnimationStateManager()
        performanceMonitor = AnimationPerformanceMonitor()
    }
    
    override func tearDownWithError() throws {
        hapticManager = nil
        animationManager = nil
        performanceMonitor = nil
    }
    
    // MARK: - Haptic Feedback Manager Tests
    
    func testHapticFeedbackManagerSingleton() throws {
        let manager1 = HapticFeedbackManager.shared
        let manager2 = HapticFeedbackManager.shared
        XCTAssertTrue(manager1 === manager2, "HapticFeedbackManager should be a singleton")
    }
    
    func testHapticFeedbackMethods() throws {
        // Test that haptic methods don't crash
        // Note: We can't test actual haptic feedback in unit tests
        XCTAssertNoThrow(hapticManager.keyPress())
        XCTAssertNoThrow(hapticManager.keySwipe())
        XCTAssertNoThrow(hapticManager.keySelection())
        XCTAssertNoThrow(hapticManager.wordCompletion())
        XCTAssertNoThrow(hapticManager.error())
        XCTAssertNoThrow(hapticManager.warning())
    }
    
    // MARK: - Animation State Manager Tests
    
    func testAnimationStateManagerInitialization() throws {
        XCTAssertTrue(animationManager.highlightedKeys.isEmpty)
        XCTAssertTrue(animationManager.pressedKeys.isEmpty)
        XCTAssertNil(animationManager.swipeDirection)
        XCTAssertFalse(animationManager.isLayoutTransitioning)
    }
    
    func testHighlightKeyManagement() throws {
        // Test highlighting a key
        animationManager.highlightKey(0, duration: 0.1)
        XCTAssertTrue(animationManager.highlightedKeys.contains(0))
        
        // Wait for highlight to be removed
        let expectation = XCTestExpectation(description: "Key highlight removed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            XCTAssertFalse(self.animationManager.highlightedKeys.contains(0))
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.5)
    }
    
    func testKeyPressedStateManagement() throws {
        // Test setting key pressed
        animationManager.setKeyPressed(1, isPressed: true)
        XCTAssertTrue(animationManager.pressedKeys.contains(1))
        
        // Test removing key pressed
        animationManager.setKeyPressed(1, isPressed: false)
        XCTAssertFalse(animationManager.pressedKeys.contains(1))
    }
    
    func testSwipeDirectionDisplay() throws {
        // Test showing swipe direction
        animationManager.showSwipeDirection(.right, duration: 0.1)
        XCTAssertEqual(animationManager.swipeDirection, .right)
        
        // Wait for swipe direction to be cleared
        let expectation = XCTestExpectation(description: "Swipe direction cleared")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            XCTAssertNil(self.animationManager.swipeDirection)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.5)
    }
    
    func testLayoutTransition() throws {
        // Test starting layout transition
        animationManager.startLayoutTransition(duration: 0.1)
        XCTAssertTrue(animationManager.isLayoutTransitioning)
        
        // Wait for transition to complete
        let expectation = XCTestExpectation(description: "Layout transition completed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            XCTAssertFalse(self.animationManager.isLayoutTransitioning)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.5)
    }
    
    func testClearAllStates() throws {
        // Set up some states
        animationManager.highlightKey(0)
        animationManager.setKeyPressed(1, isPressed: true)
        animationManager.showSwipeDirection(.left)
        animationManager.startLayoutTransition()
        
        // Clear all states
        animationManager.clearAllStates()
        
        XCTAssertTrue(animationManager.highlightedKeys.isEmpty)
        XCTAssertTrue(animationManager.pressedKeys.isEmpty)
        XCTAssertNil(animationManager.swipeDirection)
        XCTAssertFalse(animationManager.isLayoutTransitioning)
    }
    
    // MARK: - Animation Performance Monitor Tests
    
    func testPerformanceMonitorInitialization() throws {
        XCTAssertEqual(performanceMonitor.frameRate, 60.0)
        XCTAssertTrue(performanceMonitor.isOptimized)
    }
    
    func testFrameRateRecording() throws {
        // Record some frames
        for _ in 0..<10 {
            performanceMonitor.recordFrame()
            Thread.sleep(forTimeInterval: 0.016) // ~60fps
        }
        
        // Frame rate should be reasonable (allowing for test environment variance)
        XCTAssertGreaterThan(performanceMonitor.frameRate, 30.0)
        XCTAssertLessThan(performanceMonitor.frameRate, 120.0)
    }
    
    func testPerformanceMonitorReset() throws {
        // Record some frames
        performanceMonitor.recordFrame()
        performanceMonitor.recordFrame()
        
        // Reset
        performanceMonitor.reset()
        
        // Should be back to initial state
        XCTAssertEqual(performanceMonitor.frameRate, 60.0)
        XCTAssertTrue(performanceMonitor.isOptimized)
    }
    
    // MARK: - Animation Configuration Tests
    
    func testAnimationConfigurations() throws {
        // Test that animation configurations are defined
        XCTAssertNotNil(AnimationConfig.keyPress)
        XCTAssertNotNil(AnimationConfig.keyHighlight)
        XCTAssertNotNil(AnimationConfig.keySwipe)
        XCTAssertNotNil(AnimationConfig.layoutTransition)
        XCTAssertNotNil(AnimationConfig.pulse)
    }
    
    func testAnimationPreferences() throws {
        // Test accessibility preferences
        let reduceMotion = AnimationPreferences.reduceMotion
        let prefersCrossFade = AnimationPreferences.prefersCrossFadeTransitions
        
        // These should not crash and should return boolean values
        XCTAssertTrue(reduceMotion is Bool)
        XCTAssertTrue(prefersCrossFade is Bool)
        
        // Test optimized animation
        let testAnimation = Animation.easeInOut(duration: 0.3)
        let optimizedAnimation = AnimationPreferences.optimizedAnimation(testAnimation, value: true)
        XCTAssertNotNil(optimizedAnimation)
    }
    
    // MARK: - Haptic Feedback Type Tests
    
    func testHapticFeedbackTypes() throws {
        let types: [HapticFeedbackType] = [
            .keyPress, .keySwipe, .selection, .wordCompletion, .error, .warning
        ]
        
        // Test that all types are defined
        XCTAssertEqual(types.count, 6)
        
        // Test that each type can be used
        for type in types {
            XCTAssertNotNil(type)
        }
    }
    
    // MARK: - Performance Tests
    
    func testAnimationStateManagerPerformance() throws {
        measure {
            for i in 0..<100 {
                animationManager.highlightKey(i % 10, duration: 0.01)
                animationManager.setKeyPressed(i % 5, isPressed: i % 2 == 0)
                if i % 10 == 0 {
                    animationManager.showSwipeDirection(.right, duration: 0.01)
                }
            }
        }
    }
    
    func testHapticFeedbackPerformance() throws {
        measure {
            for _ in 0..<100 {
                hapticManager.keyPress()
                hapticManager.keySwipe()
                hapticManager.keySelection()
            }
        }
    }
    
    func testPerformanceMonitorOverhead() throws {
        measure {
            for _ in 0..<1000 {
                performanceMonitor.recordFrame()
            }
        }
    }
    
    // MARK: - Integration Tests
    
    func testAnimationStateManagerWithMultipleKeys() throws {
        // Test highlighting multiple keys simultaneously
        for i in 0..<5 {
            animationManager.highlightKey(i, duration: 0.5)
        }
        
        XCTAssertEqual(animationManager.highlightedKeys.count, 5)
        
        // Test pressing multiple keys
        for i in 0..<3 {
            animationManager.setKeyPressed(i, isPressed: true)
        }
        
        XCTAssertEqual(animationManager.pressedKeys.count, 3)
        
        // Clear all and verify
        animationManager.clearAllStates()
        XCTAssertTrue(animationManager.highlightedKeys.isEmpty)
        XCTAssertTrue(animationManager.pressedKeys.isEmpty)
    }
    
    func testConcurrentAnimationOperations() throws {
        let expectation = XCTestExpectation(description: "Concurrent operations completed")
        
        DispatchQueue.concurrentPerform(iterations: 10) { index in
            animationManager.highlightKey(index, duration: 0.1)
            animationManager.setKeyPressed(index, isPressed: true)
            
            if index == 9 {
                DispatchQueue.main.async {
                    expectation.fulfill()
                }
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
        
        // Verify that operations completed without crashes
        XCTAssertGreaterThan(animationManager.highlightedKeys.count, 0)
        XCTAssertGreaterThan(animationManager.pressedKeys.count, 0)
    }
}
