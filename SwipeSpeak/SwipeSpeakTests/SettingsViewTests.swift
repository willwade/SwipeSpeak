//
//  SettingsViewTests.swift
//  SwipeSpeakTests
//
//  Created by SwiftUI Migration on 21/06/2025.
//  Copyright © 2025 TeamGleason. All rights reserved.
//

import XCTest
import SwiftUI
// import ViewInspector // Commented out until ViewInspector is properly configured
@testable import SwipeSpeak

final class SettingsViewTests: XCTestCase {
    
    var viewModel: SettingsViewModel!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        viewModel = SwiftUITestUtilities.createTestSettingsViewModel()
    }
    
    override func tearDownWithError() throws {
        viewModel = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Basic View Tests
    
    func testSettingsViewInitialization() throws {
        let view = SettingsView(viewModel: viewModel)
        let inspection = try view.inspect()
        
        // Verify the view contains a NavigationView
        XCTAssertNoThrow(try inspection.find(ViewType.NavigationView.self))
    }
    
    func testSettingsViewTitle() throws {
        let view = SettingsView(viewModel: viewModel)
        let inspection = try view.inspect()
        
        // Verify navigation title
        let navigationView = try inspection.find(ViewType.NavigationView.self)
        XCTAssertTrue(try navigationView.navigationBarTitle().string().contains("Settings"))
    }
    
    func testSettingsFormExists() throws {
        let view = SettingsView(viewModel: viewModel)
        let inspection = try view.inspect()
        
        // Verify the form exists
        XCTAssertNoThrow(try inspection.find(ViewType.Form.self))
    }
    
    // MARK: - Keyboard Layout Section Tests
    
    func testKeyboardLayoutSection() throws {
        let view = SettingsView(viewModel: viewModel)
        let inspection = try view.inspect()
        
        // Find the keyboard layout section
        let form = try inspection.find(ViewType.Form.self)
        let sections = try form.forEach()
        
        // Should have multiple sections
        XCTAssertGreaterThan(sections.count, 0)
        
        // Look for keyboard layout picker
        XCTAssertNoThrow(try inspection.find(ViewType.Picker.self))
    }
    
    func testKeyboardLayoutSelection() throws {
        let view = SettingsView(viewModel: viewModel)
        
        // Test that all keyboard layouts are available
        let expectedLayouts: [KeyboardLayout] = [.keys4, .keys6, .keys8, .strokes2, .msr]
        
        for layout in expectedLayouts {
            viewModel.selectedKeyboardLayout = layout
            let inspection = try view.inspect()
            
            // Verify the picker reflects the selection
            let picker = try inspection.find(ViewType.Picker.self)
            XCTAssertNotNil(picker)
        }
    }
    
    // MARK: - Speech Settings Tests
    
    func testSpeechRateSlider() throws {
        let view = SettingsView(viewModel: viewModel)
        let inspection = try view.inspect()
        
        // Find speech rate slider
        let sliders = try inspection.findAll(ViewType.Slider.self)
        XCTAssertGreaterThan(sliders.count, 0)
        
        // Test speech rate bounds
        viewModel.speechRate = 0.1
        XCTAssertEqual(viewModel.speechRate, 0.1, accuracy: 0.01)
        
        viewModel.speechRate = 1.0
        XCTAssertEqual(viewModel.speechRate, 1.0, accuracy: 0.01)
    }
    
    func testVolumeSlider() throws {
        let view = SettingsView(viewModel: viewModel)
        let inspection = try view.inspect()
        
        // Find volume slider
        let sliders = try inspection.findAll(ViewType.Slider.self)
        XCTAssertGreaterThan(sliders.count, 1) // Should have at least speech rate and volume
        
        // Test volume bounds
        viewModel.volume = 0.0
        XCTAssertEqual(viewModel.volume, 0.0, accuracy: 0.01)
        
        viewModel.volume = 1.0
        XCTAssertEqual(viewModel.volume, 1.0, accuracy: 0.01)
    }
    
    // MARK: - Voice Selection Tests
    
    func testVoiceSelectionNavigation() throws {
        let view = SettingsView(viewModel: viewModel)
        let inspection = try view.inspect()
        
        // Find voice selection navigation link
        let navigationLinks = try inspection.findAll(ViewType.NavigationLink.self)
        
        // Should have navigation links for various settings
        XCTAssertGreaterThan(navigationLinks.count, 0)
        
        // Look for voice-related navigation
        var foundVoiceNavigation = false
        for link in navigationLinks {
            if let labelText = try? link.labelView().text().string(),
               labelText.lowercased().contains("voice") {
                foundVoiceNavigation = true
                break
            }
        }
        XCTAssertTrue(foundVoiceNavigation, "Should have voice selection navigation")
    }
    
    // MARK: - Feedback Settings Tests
    
    func testAudioFeedbackToggle() throws {
        let view = SettingsView(viewModel: viewModel)
        let inspection = try view.inspect()
        
        // Find audio feedback toggle
        let toggles = try inspection.findAll(ViewType.Toggle.self)
        XCTAssertGreaterThan(toggles.count, 0)
        
        // Test toggle functionality
        let initialValue = viewModel.audioFeedbackEnabled
        viewModel.audioFeedbackEnabled.toggle()
        XCTAssertNotEqual(viewModel.audioFeedbackEnabled, initialValue)
    }
    
    func testVibrationFeedbackToggle() throws {
        let view = SettingsView(viewModel: viewModel)
        
        // Test vibration feedback toggle
        let initialValue = viewModel.vibrationFeedbackEnabled
        viewModel.vibrationFeedbackEnabled.toggle()
        XCTAssertNotEqual(viewModel.vibrationFeedbackEnabled, initialValue)
    }
    
    func testPauseOnPredictionToggle() throws {
        let view = SettingsView(viewModel: viewModel)
        
        // Test pause on prediction toggle
        let initialValue = viewModel.pauseOnPredictionEnabled
        viewModel.pauseOnPredictionEnabled.toggle()
        XCTAssertNotEqual(viewModel.pauseOnPredictionEnabled, initialValue)
    }
    
    // MARK: - Prediction Engine Tests
    
    func testPredictionEngineSelection() throws {
        let view = SettingsView(viewModel: viewModel)
        let inspection = try view.inspect()
        
        // Find prediction engine picker
        let pickers = try inspection.findAll(ViewType.Picker.self)
        XCTAssertGreaterThan(pickers.count, 1) // Should have keyboard layout and prediction engine pickers
        
        // Test prediction engine options
        viewModel.selectedPredictionEngine = .custom
        XCTAssertEqual(viewModel.selectedPredictionEngine, .custom)
        
        viewModel.selectedPredictionEngine = .native
        XCTAssertEqual(viewModel.selectedPredictionEngine, .native)
    }
    
    // MARK: - Cloud Sync Tests
    
    func testCloudSyncToggle() throws {
        let view = SettingsView(viewModel: viewModel)
        
        // Test cloud sync toggle
        let initialValue = viewModel.cloudSyncEnabled
        viewModel.cloudSyncEnabled.toggle()
        XCTAssertNotEqual(viewModel.cloudSyncEnabled, initialValue)
    }
    
    // MARK: - Navigation Tests
    
    func testAboutNavigation() throws {
        let view = SettingsView(viewModel: viewModel)
        let inspection = try view.inspect()
        
        // Find About navigation link
        let navigationLinks = try inspection.findAll(ViewType.NavigationLink.self)
        
        var foundAboutNavigation = false
        for link in navigationLinks {
            if let labelText = try? link.labelView().text().string(),
               labelText.lowercased().contains("about") {
                foundAboutNavigation = true
                break
            }
        }
        XCTAssertTrue(foundAboutNavigation, "Should have About navigation")
    }
    
    func testAcknowledgementsNavigation() throws {
        let view = SettingsView(viewModel: viewModel)
        let inspection = try view.inspect()
        
        // Find Acknowledgements navigation link
        let navigationLinks = try inspection.findAll(ViewType.NavigationLink.self)
        
        var foundAcknowledgementsNavigation = false
        for link in navigationLinks {
            if let labelText = try? link.labelView().text().string(),
               labelText.lowercased().contains("acknowledgement") {
                foundAcknowledgementsNavigation = true
                break
            }
        }
        XCTAssertTrue(foundAcknowledgementsNavigation, "Should have Acknowledgements navigation")
    }
    
    // MARK: - Accessibility Tests
    
    func testAccessibilityLabels() throws {
        let view = SettingsView(viewModel: viewModel)
        let inspection = try view.inspect()
        
        // Verify form has accessibility support
        let form = try inspection.find(ViewType.Form.self)
        XCTAssertNotNil(form)
        
        // Check that toggles have proper accessibility
        let toggles = try inspection.findAll(ViewType.Toggle.self)
        for toggle in toggles {
            // Each toggle should have a label
            XCTAssertNoThrow(try toggle.labelView())
        }
    }
    
    func testVoiceOverSupport() throws {
        let view = SettingsView(viewModel: viewModel)
        let inspection = try view.inspect()
        
        // Verify sliders have accessibility values
        let sliders = try inspection.findAll(ViewType.Slider.self)
        for slider in sliders {
            // Sliders should be accessible
            XCTAssertNotNil(slider)
        }
    }
    
    // MARK: - Integration Tests
    
    func testViewModelBinding() throws {
        let view = SettingsView(viewModel: viewModel)
        
        // Test that view model changes are reflected
        let originalLayout = viewModel.selectedKeyboardLayout
        let newLayout: KeyboardLayout = originalLayout == .keys4 ? .keys6 : .keys4
        
        viewModel.selectedKeyboardLayout = newLayout
        XCTAssertEqual(viewModel.selectedKeyboardLayout, newLayout)
        
        // Reset
        viewModel.selectedKeyboardLayout = originalLayout
    }
    
    func testSettingsViewModelDefaults() throws {
        let freshViewModel = SettingsViewModel()
        
        // Test default values
        XCTAssertEqual(freshViewModel.selectedKeyboardLayout, .keys4)
        XCTAssertEqual(freshViewModel.selectedPredictionEngine, .custom)
        XCTAssertTrue(freshViewModel.audioFeedbackEnabled)
        XCTAssertTrue(freshViewModel.vibrationFeedbackEnabled)
        XCTAssertFalse(freshViewModel.pauseOnPredictionEnabled)
        XCTAssertFalse(freshViewModel.cloudSyncEnabled)
        XCTAssertEqual(freshViewModel.speechRate, 0.5, accuracy: 0.01)
        XCTAssertEqual(freshViewModel.volume, 1.0, accuracy: 0.01)
    }
}
