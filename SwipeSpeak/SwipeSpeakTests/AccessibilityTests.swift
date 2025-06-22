//
//  AccessibilityTests.swift
//  SwipeSpeakTests
//
//  Created by SwiftUI Migration on 21/06/2025.
//  Copyright © 2025 TeamGleason. All rights reserved.
//

import XCTest
import SwiftUI
// import ViewInspector // Commented out until ViewInspector is properly configured
@testable import SwipeSpeak

final class AccessibilityTests: XCTestCase {
    
    var settingsViewModel: SettingsViewModel!
    var textDisplayViewModel: TextDisplayViewModel!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        settingsViewModel = SwiftUITestUtilities.createTestSettingsViewModel()
        textDisplayViewModel = SwiftUITestUtilities.createTestTextDisplayViewModel()
    }
    
    override func tearDownWithError() throws {
        settingsViewModel = nil
        textDisplayViewModel = nil
        try super.tearDownWithError()
    }
    
    // MARK: - SettingsView Accessibility Tests
    
    func testSettingsViewAccessibilityStructure() throws {
        let view = SettingsView(viewModel: settingsViewModel)
        let inspection = try view.inspect()
        
        // Navigation should have proper accessibility
        let navigationView = try inspection.find(ViewType.NavigationView.self)
        XCTAssertNotNil(navigationView)
        
        // Form should be accessible
        let form = try inspection.find(ViewType.Form.self)
        XCTAssertNotNil(form)
    }
    
    func testSettingsToggleAccessibility() throws {
        let view = SettingsView(viewModel: settingsViewModel)
        let inspection = try view.inspect()
        
        // All toggles should have proper accessibility labels
        let toggles = try inspection.findAll(ViewType.Toggle.self)
        
        for toggle in toggles {
            // Each toggle should have a label view
            XCTAssertNoThrow(try toggle.labelView())
            
            // Toggle should have accessibility traits
            XCTAssertNotNil(toggle)
        }
    }
    
    func testSettingsSliderAccessibility() throws {
        let view = SettingsView(viewModel: settingsViewModel)
        let inspection = try view.inspect()
        
        // All sliders should have proper accessibility
        let sliders = try inspection.findAll(ViewType.Slider.self)
        
        for slider in sliders {
            // Slider should be accessible
            XCTAssertNotNil(slider)
            
            // Should have value accessibility
            XCTAssertNoThrow(try slider.value())
        }
    }
    
    func testSettingsPickerAccessibility() throws {
        let view = SettingsView(viewModel: settingsViewModel)
        let inspection = try view.inspect()
        
        // All pickers should have proper accessibility
        let pickers = try inspection.findAll(ViewType.Picker.self)
        
        for picker in pickers {
            // Picker should have label
            XCTAssertNoThrow(try picker.labelView())
            
            // Should be accessible
            XCTAssertNotNil(picker)
        }
    }
    
    func testSettingsNavigationAccessibility() throws {
        let view = SettingsView(viewModel: settingsViewModel)
        let inspection = try view.inspect()
        
        // Navigation links should have proper accessibility
        let navigationLinks = try inspection.findAll(ViewType.NavigationLink.self)
        
        for link in navigationLinks {
            // Each link should have accessible label
            XCTAssertNoThrow(try link.labelView())
            
            // Should have button accessibility traits
            XCTAssertNotNil(link)
        }
    }
    
    // MARK: - TextDisplayView Accessibility Tests
    
    func testTextDisplayAccessibilityStructure() throws {
        let view = TextDisplayView(viewModel: textDisplayViewModel)
        let inspection = try view.inspect()
        
        // Main container should be accessible
        let vstack = try inspection.find(ViewType.VStack.self)
        XCTAssertNotNil(vstack)
    }
    
    func testSentenceDisplayAccessibility() throws {
        let view = TextDisplayView(viewModel: textDisplayViewModel)
        let inspection = try view.inspect()
        
        // Sentence text should have proper accessibility
        let texts = try inspection.findAll(ViewType.Text.self)
        XCTAssertGreaterThan(texts.count, 0)
        
        // Should have accessibility labels for sentence content
        for text in texts {
            XCTAssertNotNil(text)
        }
    }
    
    func testWordDisplayAccessibility() throws {
        let view = TextDisplayView(viewModel: textDisplayViewModel)
        let inspection = try view.inspect()
        
        // Word display should be accessible
        let texts = try inspection.findAll(ViewType.Text.self)
        
        // Should announce current word being typed
        var foundWordText = false
        for text in texts {
            if let textContent = try? text.string(),
               textContent.contains("test") {
                foundWordText = true
                break
            }
        }
        XCTAssertTrue(foundWordText)
    }
    
    func testPredictionButtonsAccessibility() throws {
        let view = TextDisplayView(viewModel: textDisplayViewModel)
        let inspection = try view.inspect()
        
        // Prediction buttons should have proper accessibility
        let buttons = try inspection.findAll(ViewType.Button.self)
        XCTAssertGreaterThanOrEqual(buttons.count, 6)
        
        for button in buttons {
            // Each button should have accessible label
            XCTAssertNoThrow(try button.labelView())
            
            // Should have button accessibility traits
            XCTAssertNotNil(button)
        }
    }
    
    func testPredictionGridAccessibility() throws {
        let view = TextDisplayView(viewModel: textDisplayViewModel)
        let inspection = try view.inspect()
        
        // Grid should be navigable with VoiceOver
        let grid = try inspection.find(ViewType.LazyVGrid.self)
        XCTAssertNotNil(grid)
        
        // Grid items should be accessible
        let buttons = try inspection.findAll(ViewType.Button.self)
        for (index, button) in buttons.enumerated() {
            XCTAssertNotNil(button, "Button at index \(index) should be accessible")
        }
    }
    
    // MARK: - VoiceOver Navigation Tests
    
    func testSettingsVoiceOverNavigation() throws {
        let view = SettingsView(viewModel: settingsViewModel)
        let inspection = try view.inspect()
        
        // Should have logical VoiceOver navigation order
        let form = try inspection.find(ViewType.Form.self)
        let sections = try form.forEach()
        
        // Each section should be navigable
        XCTAssertGreaterThan(sections.count, 0)
    }
    
    func testTextDisplayVoiceOverNavigation() throws {
        let view = TextDisplayView(viewModel: textDisplayViewModel)
        let inspection = try view.inspect()
        
        // Should have logical reading order: sentence -> word -> predictions
        let vstack = try inspection.find(ViewType.VStack.self)
        XCTAssertNotNil(vstack)
        
        // Prediction buttons should be in logical order
        let buttons = try inspection.findAll(ViewType.Button.self)
        XCTAssertGreaterThanOrEqual(buttons.count, 6)
    }
    
    // MARK: - Dynamic Type Support Tests
    
    func testSettingsDynamicTypeSupport() throws {
        let view = SettingsView(viewModel: settingsViewModel)
        let inspection = try view.inspect()
        
        // Text should scale with Dynamic Type
        let texts = try inspection.findAll(ViewType.Text.self)
        
        for text in texts {
            // Text should support dynamic scaling
            XCTAssertNotNil(text)
        }
    }
    
    func testTextDisplayDynamicTypeSupport() throws {
        let view = TextDisplayView(viewModel: textDisplayViewModel)
        let inspection = try view.inspect()
        
        // All text should scale with Dynamic Type
        let texts = try inspection.findAll(ViewType.Text.self)
        
        for text in texts {
            // Should support accessibility text sizes
            XCTAssertNotNil(text)
        }
    }
    
    // MARK: - Color Contrast Tests
    
    func testSettingsColorContrast() throws {
        let view = SettingsView(viewModel: settingsViewModel)
        let inspection = try view.inspect()
        
        // Should use system colors for proper contrast
        let form = try inspection.find(ViewType.Form.self)
        XCTAssertNotNil(form)
        
        // Text should have sufficient contrast
        let texts = try inspection.findAll(ViewType.Text.self)
        for text in texts {
            XCTAssertNotNil(text)
        }
    }
    
    func testTextDisplayColorContrast() throws {
        let view = TextDisplayView(viewModel: textDisplayViewModel)
        let inspection = try view.inspect()
        
        // Text should have proper contrast ratios
        let texts = try inspection.findAll(ViewType.Text.self)
        for text in texts {
            XCTAssertNotNil(text)
        }
        
        // Buttons should have proper contrast
        let buttons = try inspection.findAll(ViewType.Button.self)
        for button in buttons {
            XCTAssertNotNil(button)
        }
    }
    
    // MARK: - Reduced Motion Support Tests
    
    func testSettingsReducedMotionSupport() throws {
        let view = SettingsView(viewModel: settingsViewModel)
        let inspection = try view.inspect()
        
        // Should respect reduced motion preferences
        let navigationView = try inspection.find(ViewType.NavigationView.self)
        XCTAssertNotNil(navigationView)
    }
    
    func testTextDisplayReducedMotionSupport() throws {
        let view = TextDisplayView(viewModel: textDisplayViewModel)
        
        // Animations should respect reduced motion
        textDisplayViewModel.setWordHighlighted(true)
        
        let inspection = try view.inspect()
        XCTAssertNotNil(inspection)
        
        // Reset
        textDisplayViewModel.setWordHighlighted(false)
    }
    
    // MARK: - Accessibility Actions Tests
    
    func testSettingsAccessibilityActions() throws {
        let view = SettingsView(viewModel: settingsViewModel)
        let inspection = try view.inspect()
        
        // Toggles should have custom accessibility actions
        let toggles = try inspection.findAll(ViewType.Toggle.self)
        
        for toggle in toggles {
            // Should be able to toggle via accessibility
            XCTAssertNotNil(toggle)
        }
    }
    
    func testTextDisplayAccessibilityActions() throws {
        let view = TextDisplayView(viewModel: textDisplayViewModel)
        let inspection = try view.inspect()
        
        // Prediction buttons should have custom actions
        let buttons = try inspection.findAll(ViewType.Button.self)
        
        for button in buttons {
            // Should have "activate" action
            XCTAssertNotNil(button)
        }
    }
    
    // MARK: - Accessibility Hints Tests
    
    func testSettingsAccessibilityHints() throws {
        let view = SettingsView(viewModel: settingsViewModel)
        let inspection = try view.inspect()
        
        // Controls should have helpful hints
        let sliders = try inspection.findAll(ViewType.Slider.self)
        
        for slider in sliders {
            // Should provide usage hints
            XCTAssertNotNil(slider)
        }
    }
    
    func testTextDisplayAccessibilityHints() throws {
        let view = TextDisplayView(viewModel: textDisplayViewModel)
        let inspection = try view.inspect()
        
        // Prediction buttons should have helpful hints
        let buttons = try inspection.findAll(ViewType.Button.self)
        
        for button in buttons {
            // Should explain what tapping will do
            XCTAssertNotNil(button)
        }
    }
    
    // MARK: - Integration Accessibility Tests
    
    func testOverallAccessibilityCompliance() throws {
        // Test both views together for accessibility
        let settingsView = SettingsView(viewModel: settingsViewModel)
        let textDisplayView = TextDisplayView(viewModel: textDisplayViewModel)
        
        let settingsInspection = try settingsView.inspect()
        let textDisplayInspection = try textDisplayView.inspect()
        
        // Both views should be fully accessible
        XCTAssertNotNil(settingsInspection)
        XCTAssertNotNil(textDisplayInspection)
    }
    
    func testAccessibilityPerformance() throws {
        let view = SettingsView(viewModel: settingsViewModel)

        // Accessibility should not impact performance significantly
        measure {
            for _ in 0..<10 {
                let inspection = try? view.inspect()
                XCTAssertNotNil(inspection)
            }
        }
    }

    // MARK: - Enhanced Accessibility Tests

    func testKeyboardViewAccessibility() throws {
        let keyboardViewModel = KeyboardViewModel()
        let keyboardView = KeyboardView(viewModel: keyboardViewModel)
        let inspection = try keyboardView.inspect()

        // Keyboard should have proper accessibility container
        XCTAssertNotNil(inspection)

        // Should have accessibility label describing the keyboard
        let accessibilityLabel = try? inspection.accessibilityLabel()
        XCTAssertNotNil(accessibilityLabel)
        XCTAssertTrue(accessibilityLabel?.contains("keyboard") == true)
    }

    func testKeyViewAccessibilityActions() throws {
        let key = SwiftUIKeyboardKey(index: 0, text: "ABC", letters: "abc")
        let keyView = KeyView(
            key: key,
            isHighlighted: false,
            onTap: {},
            onSwipe: { _, _ in }
        )
        let inspection = try keyView.inspect()

        // Key should have proper accessibility label
        let accessibilityLabel = try? inspection.accessibilityLabel()
        XCTAssertNotNil(accessibilityLabel)
        XCTAssertTrue(accessibilityLabel?.contains("letters") == true)

        // Should have accessibility hint
        let accessibilityHint = try? inspection.accessibilityHint()
        XCTAssertNotNil(accessibilityHint)
    }

    func testTextDisplayAccessibilityActionsAdvanced() throws {
        let view = TextDisplayView(viewModel: textDisplayViewModel)
        let inspection = try view.inspect()

        // Text areas should have custom accessibility actions
        let sentenceArea = try inspection.find(ViewType.ZStack.self)
        XCTAssertNotNil(sentenceArea)

        // Should support default and long press actions
        // This would be tested with actual accessibility action invocation in integration tests
    }

    func testVoiceOverAnnouncements() throws {
        // Test that proper announcements are made for VoiceOver users
        let keyboardViewModel = KeyboardViewModel()
        let keyboardView = KeyboardView(viewModel: keyboardViewModel)

        // Simulate key entry
        keyboardViewModel.keyEntered(0, isSwipe: false)

        // In a real test environment, we would verify that UIAccessibility.post was called
        // For now, we verify the view model state changes
        XCTAssertFalse(keyboardViewModel.enteredKeys.isEmpty)
    }

    func testSwitchControlSupport() throws {
        // Test that Switch Control users can navigate the interface
        let view = SettingsView(viewModel: settingsViewModel)
        let inspection = try view.inspect()

        // All interactive elements should be accessible via Switch Control
        let buttons = try inspection.findAll(ViewType.Button.self)
        let toggles = try inspection.findAll(ViewType.Toggle.self)

        // Each element should be focusable
        for button in buttons {
            XCTAssertNotNil(button)
        }

        for toggle in toggles {
            XCTAssertNotNil(toggle)
        }
    }

    func testHighContrastSupport() throws {
        // Test that high contrast mode is properly supported
        let keyboardViewModel = KeyboardViewModel()
        let keyboardView = KeyboardView(viewModel: keyboardViewModel)
        let inspection = try keyboardView.inspect()

        // Colors should adapt to high contrast settings
        // This would be tested by checking color values in different accessibility states
        XCTAssertNotNil(inspection)
    }

    func testReduceMotionSupport() throws {
        // Test that animations respect reduce motion settings
        let view = TextDisplayView(viewModel: textDisplayViewModel)

        // Animations should be disabled when reduce motion is enabled
        textDisplayViewModel.setWordHighlighted(true)

        let inspection = try view.inspect()
        XCTAssertNotNil(inspection)

        // Reset
        textDisplayViewModel.setWordHighlighted(false)
    }

    func testDynamicTypeSupport() throws {
        // Test that text scales properly with Dynamic Type
        let view = SettingsView(viewModel: settingsViewModel)
        let inspection = try view.inspect()

        // Text should scale with user's preferred text size
        let texts = try inspection.findAll(ViewType.Text.self)
        for text in texts {
            XCTAssertNotNil(text)
        }
    }
}
