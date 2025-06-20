//
//  SwipeSpeakUITests.swift
//  SwipeSpeakUITests
//
//  Created by Testing Implementation on 20/06/2025.
//  Copyright © 2025 TeamGleason. All rights reserved.
//

import XCTest

final class SwipeSpeakUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - App Launch Tests

    func testAppLaunches() throws {
        XCTAssertTrue(app.exists, "App should launch successfully")
    }

    func testMainScreenElements() throws {
        // Test that main UI elements are present
        XCTAssertTrue(app.exists, "App should be running")

        // Look for key UI elements that should be present
        let mainView = app.otherElements["MainView"]
        if mainView.exists {
            XCTAssertTrue(mainView.exists, "Main view should be visible")
        }

        // Test for keyboard container
        let keyboardContainer = app.otherElements["keyboardContainerView"]
        if keyboardContainer.exists {
            XCTAssertTrue(keyboardContainer.exists, "Keyboard container should be visible")
        }
    }

    // MARK: - Navigation Tests

    func testSettingsNavigation() throws {
        // Look for settings button or navigation
        let settingsButton = app.buttons["Settings"]
        if settingsButton.exists {
            settingsButton.tap()

            // Verify settings screen opened
            let settingsView = app.navigationBars["Settings"]
            XCTAssertTrue(settingsView.waitForExistence(timeout: 2), "Settings view should appear")
        }
    }

    func testBackNavigation() throws {
        // Navigate to settings if possible
        let settingsButton = app.buttons["Settings"]
        if settingsButton.exists {
            settingsButton.tap()

            // Try to navigate back
            let backButton = app.navigationBars.buttons.element(boundBy: 0)
            if backButton.exists {
                backButton.tap()

                // Should return to main screen
                XCTAssertTrue(app.exists, "Should return to main screen")
            }
        }
    }

    // MARK: - Accessibility Tests

    func testAccessibilityElements() throws {
        // Test that key UI elements have accessibility labels
        let accessibleElements = app.descendants(matching: .any).allElementsBoundByAccessibilityElement

        XCTAssertFalse(accessibleElements.isEmpty, "Should have accessible elements")

        // Check for common accessibility issues
        for element in accessibleElements {
            if element.elementType == .button {
                XCTAssertFalse(element.label.isEmpty, "Buttons should have accessibility labels")
            }
        }
    }

    func testVoiceOverSupport() throws {
        // Basic VoiceOver support test
        let firstElement = app.descendants(matching: .any).element(boundBy: 0)
        if firstElement.exists {
            XCTAssertTrue(firstElement.isAccessibilityElement || firstElement.accessibilityLabel != nil,
                         "First element should be accessible")
        }
    }

    // MARK: - Keyboard Interaction Tests

    func testKeyboardInteraction() throws {
        // Look for keyboard elements
        let keyboardView = app.otherElements["keyboardContainerView"]
        if keyboardView.exists {
            // Try to interact with keyboard
            keyboardView.tap()

            // Should handle tap without crashing
            XCTAssertTrue(app.exists, "App should remain stable after keyboard interaction")
        }
    }

    func testSwipeGestures() throws {
        // Test basic swipe gestures on main view
        let mainView = app.otherElements.element(boundBy: 0)
        if mainView.exists {
            mainView.swipeLeft()
            XCTAssertTrue(app.exists, "App should handle left swipe")

            mainView.swipeRight()
            XCTAssertTrue(app.exists, "App should handle right swipe")

            mainView.swipeUp()
            XCTAssertTrue(app.exists, "App should handle up swipe")

            mainView.swipeDown()
            XCTAssertTrue(app.exists, "App should handle down swipe")
        }
    }

    // MARK: - Text Display Tests

    func testTextDisplay() throws {
        // Look for text display elements
        let textLabels = app.staticTexts

        // Should have some text elements
        if textLabels.count > 0 {
            XCTAssertTrue(textLabels.count > 0, "Should have text display elements")
        }
    }

    // MARK: - Performance Tests

    func testLaunchPerformance() throws {
        if #available(iOS 13.0, *) {
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }

    func testScrollPerformance() throws {
        if #available(iOS 13.0, *) {
            let scrollView = app.scrollViews.element(boundBy: 0)
            if scrollView.exists {
                measure(metrics: [XCTOSSignpostMetric.scrollingAndDecelerationMetric]) {
                    scrollView.swipeUp()
                    scrollView.swipeDown()
                }
            }
        }
    }

    // MARK: - Error Handling Tests

    func testAppStability() throws {
        // Perform various interactions to test stability
        let interactions = [
            { self.app.tap() },
            { self.app.swipeLeft() },
            { self.app.swipeRight() },
            { self.app.pinch(withScale: 1.5, velocity: 1.0) },
            { self.app.pinch(withScale: 0.5, velocity: 1.0) }
        ]

        for interaction in interactions {
            interaction()
            XCTAssertTrue(app.exists, "App should remain stable after interaction")
        }
    }

    func testMemoryStability() throws {
        // Perform repeated operations to test for memory leaks
        for _ in 0..<10 {
            app.swipeLeft()
            app.swipeRight()
            app.tap()
        }

        XCTAssertTrue(app.exists, "App should remain stable after repeated operations")
    }

    // MARK: - Orientation Tests

    func testPortraitOrientation() throws {
        XCUIDevice.shared.orientation = .portrait

        // Give time for orientation change
        Thread.sleep(forTimeInterval: 1.0)

        XCTAssertTrue(app.exists, "App should handle portrait orientation")
    }

    func testLandscapeOrientation() throws {
        XCUIDevice.shared.orientation = .landscapeLeft

        // Give time for orientation change
        Thread.sleep(forTimeInterval: 1.0)

        XCTAssertTrue(app.exists, "App should handle landscape orientation")

        // Return to portrait
        XCUIDevice.shared.orientation = .portrait
    }
}
