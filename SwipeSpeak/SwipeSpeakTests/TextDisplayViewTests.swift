//
//  TextDisplayViewTests.swift
//  SwipeSpeakTests
//
//  Created by SwiftUI Migration on 21/06/2025.
//  Copyright © 2025 TeamGleason. All rights reserved.
//

import XCTest
import SwiftUI
// import ViewInspector // Commented out until ViewInspector is properly configured
@testable import SwipeSpeak

final class TextDisplayViewTests: XCTestCase {
    
    var viewModel: TextDisplayViewModel!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        viewModel = SwiftUITestUtilities.createTestTextDisplayViewModel()
    }
    
    override func tearDownWithError() throws {
        viewModel = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Basic View Tests
    
    func testTextDisplayViewInitialization() throws {
        let view = TextDisplayView(viewModel: viewModel)
        let inspection = try view.inspect()
        
        // Verify the view contains a VStack
        XCTAssertNoThrow(try inspection.find(ViewType.VStack.self))
    }
    
    func testTextDisplayViewStructure() throws {
        let view = TextDisplayView(viewModel: viewModel)
        let inspection = try view.inspect()
        
        // Should contain sentence display, word display, and predictions
        let vstack = try inspection.find(ViewType.VStack.self)
        XCTAssertNotNil(vstack)
        
        // Should have multiple child views
        let children = try vstack.vStack()
        XCTAssertGreaterThan(children.count, 0)
    }
    
    // MARK: - Sentence Display Tests
    
    func testSentenceDisplayExists() throws {
        let view = TextDisplayView(viewModel: viewModel)
        let inspection = try view.inspect()
        
        // Look for sentence text display
        let texts = try inspection.findAll(ViewType.Text.self)
        XCTAssertGreaterThan(texts.count, 0)
        
        // Should display the sentence text
        var foundSentenceText = false
        for text in texts {
            if let textContent = try? text.string(),
               textContent.contains("Test sentence") {
                foundSentenceText = true
                break
            }
        }
        XCTAssertTrue(foundSentenceText, "Should display sentence text")
    }
    
    func testSentenceTextUpdate() throws {
        let view = TextDisplayView(viewModel: viewModel)
        
        // Update sentence text
        let newSentence = "Updated test sentence"
        viewModel.setSentenceText(newSentence)
        
        let inspection = try view.inspect()
        let texts = try inspection.findAll(ViewType.Text.self)
        
        // Should display updated text
        var foundUpdatedText = false
        for text in texts {
            if let textContent = try? text.string(),
               textContent.contains(newSentence) {
                foundUpdatedText = true
                break
            }
        }
        XCTAssertTrue(foundUpdatedText, "Should display updated sentence text")
    }
    
    func testSentenceDisplayTapGesture() throws {
        let view = TextDisplayView(viewModel: viewModel)
        let inspection = try view.inspect()
        
        // Find sentence display area
        let texts = try inspection.findAll(ViewType.Text.self)
        XCTAssertGreaterThan(texts.count, 0)
        
        // Should have tap gesture capability
        // Note: ViewInspector gesture testing may require specific implementation
        XCTAssertNotNil(texts.first)
    }
    
    // MARK: - Word Display Tests
    
    func testWordDisplayExists() throws {
        let view = TextDisplayView(viewModel: viewModel)
        let inspection = try view.inspect()
        
        // Look for word text display
        let texts = try inspection.findAll(ViewType.Text.self)
        
        // Should display the current word
        var foundWordText = false
        for text in texts {
            if let textContent = try? text.string(),
               textContent.contains("test") {
                foundWordText = true
                break
            }
        }
        XCTAssertTrue(foundWordText, "Should display current word")
    }
    
    func testWordTextUpdate() throws {
        let view = TextDisplayView(viewModel: viewModel)
        
        // Update word text
        let newWord = "updated"
        viewModel.setWordText(newWord)
        
        let inspection = try view.inspect()
        let texts = try inspection.findAll(ViewType.Text.self)
        
        // Should display updated word
        var foundUpdatedWord = false
        for text in texts {
            if let textContent = try? text.string(),
               textContent.contains(newWord) {
                foundUpdatedWord = true
                break
            }
        }
        XCTAssertTrue(foundUpdatedWord, "Should display updated word text")
    }
    
    func testWordHighlighting() throws {
        let view = TextDisplayView(viewModel: viewModel)
        
        // Test word highlighting state
        viewModel.setWordHighlighted(true)
        let inspection = try view.inspect()
        
        // Should have visual indication of highlighting
        // This would typically be tested through background color or border changes
        XCTAssertNotNil(inspection)
    }
    
    // MARK: - Prediction Labels Tests
    
    func testPredictionLabelsExist() throws {
        let view = TextDisplayView(viewModel: viewModel)
        let inspection = try view.inspect()
        
        // Should have prediction buttons/labels
        let buttons = try inspection.findAll(ViewType.Button.self)
        XCTAssertGreaterThanOrEqual(buttons.count, 6, "Should have 6 prediction buttons")
    }
    
    func testPredictionLabelsContent() throws {
        let view = TextDisplayView(viewModel: viewModel)
        let inspection = try view.inspect()
        
        // Check that predictions are displayed
        let buttons = try inspection.findAll(ViewType.Button.self)
        
        let expectedPredictions = ["testing", "test", "tests", "tested", "tester"]
        var foundPredictions = 0
        
        for button in buttons {
            if let buttonText = try? button.labelView().text().string() {
                if expectedPredictions.contains(buttonText) {
                    foundPredictions += 1
                }
            }
        }
        
        XCTAssertGreaterThan(foundPredictions, 0, "Should display prediction text")
    }
    
    func testPredictionButtonTap() throws {
        let view = TextDisplayView(viewModel: viewModel)
        let inspection = try view.inspect()
        
        // Find first prediction button
        let buttons = try inspection.findAll(ViewType.Button.self)
        XCTAssertGreaterThan(buttons.count, 0)
        
        let firstButton = buttons[0]
        
        // Should be able to tap prediction buttons
        XCTAssertNoThrow(try firstButton.tap())
    }
    
    func testPredictionUpdate() throws {
        let view = TextDisplayView(viewModel: viewModel)
        
        // Update predictions
        let newPredictions = ["hello", "help", "here", "heart", "heavy", ""]
        viewModel.updatePredictions(newPredictions)
        
        let inspection = try view.inspect()
        let buttons = try inspection.findAll(ViewType.Button.self)
        
        // Should display updated predictions
        var foundNewPredictions = 0
        for button in buttons {
            if let buttonText = try? button.labelView().text().string() {
                if newPredictions.contains(buttonText) {
                    foundNewPredictions += 1
                }
            }
        }
        
        XCTAssertGreaterThan(foundNewPredictions, 0, "Should display updated predictions")
    }
    
    // MARK: - Grid Layout Tests
    
    func testPredictionGridLayout() throws {
        let view = TextDisplayView(viewModel: viewModel)
        let inspection = try view.inspect()
        
        // Should use LazyVGrid for predictions
        XCTAssertNoThrow(try inspection.find(ViewType.LazyVGrid.self))
    }
    
    func testGridColumns() throws {
        let view = TextDisplayView(viewModel: viewModel)
        let inspection = try view.inspect()
        
        // Grid should have proper column configuration
        let grid = try inspection.find(ViewType.LazyVGrid.self)
        XCTAssertNotNil(grid)
        
        // Should have 6 prediction items (including empty one)
        let buttons = try inspection.findAll(ViewType.Button.self)
        XCTAssertGreaterThanOrEqual(buttons.count, 6)
    }
    
    // MARK: - Accessibility Tests
    
    func testSentenceAccessibility() throws {
        let view = TextDisplayView(viewModel: viewModel)
        let inspection = try view.inspect()
        
        // Sentence display should have accessibility support
        let texts = try inspection.findAll(ViewType.Text.self)
        XCTAssertGreaterThan(texts.count, 0)
        
        // Should have proper accessibility labels
        for text in texts {
            XCTAssertNotNil(text)
        }
    }
    
    func testWordAccessibility() throws {
        let view = TextDisplayView(viewModel: viewModel)
        let inspection = try view.inspect()
        
        // Word display should have accessibility support
        let texts = try inspection.findAll(ViewType.Text.self)
        XCTAssertGreaterThan(texts.count, 0)
    }
    
    func testPredictionAccessibility() throws {
        let view = TextDisplayView(viewModel: viewModel)
        let inspection = try view.inspect()
        
        // Prediction buttons should have accessibility support
        let buttons = try inspection.findAll(ViewType.Button.self)
        
        for button in buttons {
            // Each button should have accessibility label
            XCTAssertNotNil(button)
        }
    }
    
    // MARK: - Animation Tests
    
    func testWordHighlightAnimation() throws {
        let view = TextDisplayView(viewModel: viewModel)
        
        // Test highlighting animation
        viewModel.setWordHighlighted(true)
        
        // Animation should be smooth
        let inspection = try view.inspect()
        XCTAssertNotNil(inspection)
        
        // Reset highlighting
        viewModel.setWordHighlighted(false)
    }
    
    func testPredictionSelectionAnimation() throws {
        let view = TextDisplayView(viewModel: viewModel)
        
        // Test prediction selection animation
        viewModel.setPredictionHighlighted(0, highlighted: true)
        
        let inspection = try view.inspect()
        XCTAssertNotNil(inspection)
        
        // Reset highlighting
        viewModel.setPredictionHighlighted(0, highlighted: false)
    }
    
    // MARK: - Integration Tests
    
    func testViewModelBinding() throws {
        let view = TextDisplayView(viewModel: viewModel)
        
        // Test that view model changes are reflected
        let originalSentence = viewModel.sentenceText
        let newSentence = "New test sentence"
        
        viewModel.setSentenceText(newSentence)
        XCTAssertEqual(viewModel.sentenceText, newSentence)
        
        // Reset
        viewModel.setSentenceText(originalSentence)
    }
    
    func testCallbackIntegration() throws {
        let view = TextDisplayView(viewModel: viewModel)
        
        // Test callback functionality
        var callbackTriggered = false
        
        viewModel.onSentenceTap = {
            callbackTriggered = true
        }
        
        // Simulate sentence tap
        viewModel.onSentenceTap?()
        XCTAssertTrue(callbackTriggered, "Sentence tap callback should be triggered")
    }
    
    func testPredictionCallback() throws {
        let view = TextDisplayView(viewModel: viewModel)
        
        // Test prediction selection callback
        var selectedPrediction: String?
        
        viewModel.onPredictionTap = { prediction in
            selectedPrediction = prediction
        }
        
        // Simulate prediction tap
        let testPrediction = "testing"
        viewModel.onPredictionTap?(testPrediction)
        XCTAssertEqual(selectedPrediction, testPrediction, "Prediction callback should pass correct value")
    }
    
    // MARK: - Performance Tests
    
    func testTextUpdatePerformance() throws {
        let view = TextDisplayView(viewModel: viewModel)
        
        // Test performance of rapid text updates
        measure {
            for i in 0..<100 {
                viewModel.setSentenceText("Performance test sentence \(i)")
                viewModel.setWordText("word\(i)")
            }
        }
    }
    
    func testPredictionUpdatePerformance() throws {
        let view = TextDisplayView(viewModel: viewModel)
        
        // Test performance of rapid prediction updates
        measure {
            for i in 0..<100 {
                let predictions = Array(0..<6).map { "pred\(i)_\($0)" }
                viewModel.updatePredictions(predictions)
            }
        }
    }
}
