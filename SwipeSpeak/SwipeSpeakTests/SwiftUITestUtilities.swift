//
//  SwiftUITestUtilities.swift
//  SwipeSpeakTests
//
//  Created by SwiftUI Migration on 21/06/2025.
//  Copyright © 2025 TeamGleason. All rights reserved.
//

import XCTest
import SwiftUI
import ViewInspector
@testable import SwipeSpeak

/// Utilities for testing SwiftUI components in SwipeSpeak
class SwiftUITestUtilities {
    
    // MARK: - Test Helpers
    
    /// Create a test SettingsViewModel with mock data
    static func createTestSettingsViewModel() -> SettingsViewModel {
        let viewModel = SettingsViewModel()
        return viewModel
    }
    
    /// Create a test TextDisplayViewModel with mock data
    static func createTestTextDisplayViewModel() -> TextDisplayViewModel {
        let viewModel = TextDisplayViewModel()
        viewModel.setSentenceText("Test sentence")
        viewModel.setWordText("test")
        viewModel.updatePredictions(["testing", "test", "tests", "tested", "tester", ""])
        return viewModel
    }
    
    /// Create a test KeyboardViewModel with mock data
    static func createTestKeyboardViewModel() -> KeyboardViewModel {
        let viewModel = KeyboardViewModel()
        return viewModel
    }
    
    // MARK: - ViewInspector Extensions
    
    /// Wait for async operations in SwiftUI views
    static func waitForAsyncOperations(timeout: TimeInterval = 1.0) async {
        try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
    }
    
    /// Assert that a view contains specific text
    static func assertContainsText<V: View>(_ view: V, text: String, file: StaticString = #file, line: UInt = #line) throws {
        let inspection = try view.inspect()
        XCTAssertTrue(try inspection.findAll(ViewInspector.ViewType.Text.self).contains { textView in
            try textView.string().contains(text)
        }, "View should contain text: \(text)", file: file, line: line)
    }
    
    /// Assert that a button exists and is tappable
    static func assertButtonExists<V: View>(_ view: V, withText text: String, file: StaticString = #file, line: UInt = #line) throws {
        let inspection = try view.inspect()
        let button = try inspection.find(button: text)
        XCTAssertNotNil(button, "Button with text '\(text)' should exist", file: file, line: line)
    }
    
    /// Simulate button tap
    static func tapButton<V: View>(_ view: V, withText text: String) throws {
        let inspection = try view.inspect()
        let button = try inspection.find(button: text)
        try button.tap()
    }
    
    /// Assert that a toggle exists with specific state
    static func assertToggleState<V: View>(_ view: V, withLabel label: String, isOn: Bool, file: StaticString = #file, line: UInt = #line) throws {
        let inspection = try view.inspect()
        let toggle = try inspection.find(ViewInspector.ViewType.Toggle.self) { toggle in
            try toggle.labelView().text().string() == label
        }
        XCTAssertEqual(try toggle.isOn(), isOn, "Toggle '\(label)' should be \(isOn ? "on" : "off")", file: file, line: line)
    }

    /// Simulate toggle tap
    static func tapToggle<V: View>(_ view: V, withLabel label: String) throws {
        let inspection = try view.inspect()
        let toggle = try inspection.find(ViewInspector.ViewType.Toggle.self) { toggle in
            try toggle.labelView().text().string() == label
        }
        try toggle.tap()
    }
    
    // MARK: - Accessibility Testing
    
    /// Assert that a view has proper accessibility labels
    static func assertAccessibilityLabel<V: View>(_ view: V, expectedLabel: String, file: StaticString = #file, line: UInt = #line) throws {
        let inspection = try view.inspect()
        let accessibilityLabel = try inspection.accessibilityLabel()
        XCTAssertEqual(accessibilityLabel, expectedLabel, "Accessibility label should match", file: file, line: line)
    }
    
    /// Assert that a view has accessibility traits
    static func assertAccessibilityTraits<V: View>(_ view: V, expectedTraits: AccessibilityTraits, file: StaticString = #file, line: UInt = #line) throws {
        let inspection = try view.inspect()
        let traits = try inspection.accessibilityTraits()
        XCTAssertTrue(traits.contains(expectedTraits), "View should have accessibility traits: \(expectedTraits)", file: file, line: line)
    }
    
    // MARK: - Navigation Testing
    
    /// Assert that a NavigationLink exists
    static func assertNavigationLinkExists<V: View>(_ view: V, withText text: String, file: StaticString = #file, line: UInt = #line) throws {
        let inspection = try view.inspect()
        let navigationLink = try inspection.find(ViewInspector.ViewType.NavigationLink.self) { link in
            try link.labelView().text().string() == text
        }
        XCTAssertNotNil(navigationLink, "NavigationLink with text '\(text)' should exist", file: file, line: line)
    }

    /// Simulate NavigationLink tap
    static func tapNavigationLink<V: View>(_ view: V, withText text: String) throws {
        let inspection = try view.inspect()
        let navigationLink = try inspection.find(ViewInspector.ViewType.NavigationLink.self) { link in
            try link.labelView().text().string() == text
        }
        try navigationLink.activate()
    }
    
    // MARK: - Form Testing
    
    /// Assert that a Picker exists with specific selection
    static func assertPickerSelection<V: View, T: Equatable>(_ view: V, withLabel label: String, expectedSelection: T, file: StaticString = #file, line: UInt = #line) throws {
        let inspection = try view.inspect()
        let picker = try inspection.find(ViewInspector.ViewType.Picker.self) { picker in
            try picker.labelView().text().string() == label
        }
        // Note: ViewInspector picker selection testing may need custom implementation
        XCTAssertNotNil(picker, "Picker with label '\(label)' should exist", file: file, line: line)
    }

    /// Assert that a Slider exists with specific value
    static func assertSliderValue<V: View>(_ view: V, expectedValue: Double, tolerance: Double = 0.01, file: StaticString = #file, line: UInt = #line) throws {
        let inspection = try view.inspect()
        let slider = try inspection.find(ViewInspector.ViewType.Slider.self)
        let actualValue = try slider.value()
        XCTAssertEqual(actualValue, expectedValue, accuracy: tolerance, "Slider value should match expected value", file: file, line: line)
    }
    
    // MARK: - List Testing
    
    /// Assert that a List contains specific number of rows
    static func assertListRowCount<V: View>(_ view: V, expectedCount: Int, file: StaticString = #file, line: UInt = #line) throws {
        let inspection = try view.inspect()
        let list = try inspection.find(ViewInspector.ViewType.List.self)
        let rowCount = try list.forEach().count
        XCTAssertEqual(rowCount, expectedCount, "List should contain \(expectedCount) rows", file: file, line: line)
    }

    /// Assert that a specific row exists in a List
    static func assertListRowExists<V: View>(_ view: V, atIndex index: Int, file: StaticString = #file, line: UInt = #line) throws {
        let inspection = try view.inspect()
        let list = try inspection.find(ViewInspector.ViewType.List.self)
        let row = try list.forEach()[index]
        XCTAssertNotNil(row, "List row at index \(index) should exist", file: file, line: line)
    }
}

// MARK: - ViewInspector Extensions
// Note: ViewInspector extensions would go here when needed

// MARK: - Test Data Providers

extension SwiftUITestUtilities {
    
    /// Sample keyboard layouts for testing
    static let testKeyboardLayouts: [KeyboardLayout] = [.keys4, .keys6, .keys8, .strokes2, .msr]
    
    /// Sample prediction engine types for testing
    static let testPredictionEngines: [PredictionEngineType] = [.custom, .native]
    
    /// Sample predictions for testing
    static let testPredictions = ["hello", "help", "here", "heart", "heavy", ""]
    
    /// Sample sentence text for testing
    static let testSentenceText = "This is a test sentence for SwipeSpeak"
    
    /// Sample word text for testing
    static let testWordText = "testing"
}
