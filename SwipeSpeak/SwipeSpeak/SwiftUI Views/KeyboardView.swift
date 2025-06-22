//
//  KeyboardView.swift
//  SwipeSpeak
//
//  Created by SwiftUI Migration on 22/06/2025.
//  Copyright © 2025 TeamGleason. All rights reserved.
//

import SwiftUI

// MARK: - Keyboard Data Models

/// Represents a keyboard key with its display text and properties
struct KeyboardKey: Identifiable, Hashable {
    let id = UUID()
    let index: Int
    let text: String
    let letters: String
    let isSpecial: Bool
    let textColor: Color
    let backgroundColor: Color
    
    init(index: Int, text: String, letters: String = "", isSpecial: Bool = false, textColor: Color = .white, backgroundColor: Color = .clear) {
        self.index = index
        self.text = text
        self.letters = letters
        self.isSpecial = isSpecial
        self.textColor = textColor
        self.backgroundColor = backgroundColor
    }
}

/// Configuration for different keyboard layouts
struct KeyboardLayoutConfig {
    let layout: KeyboardLayout
    let gridColumns: [GridItem]
    let keyLetterGrouping: [String]
    let keys: [KeyboardKey]
    
    static func config(for layout: KeyboardLayout) -> KeyboardLayoutConfig {
        switch layout {
        case .keys4:
            return KeyboardLayoutConfig(
                layout: layout,
                gridColumns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2),
                keyLetterGrouping: Constants.keyLetterGrouping4Keys,
                keys: createKeys(for: layout, grouping: Constants.keyLetterGrouping4Keys)
            )
        case .keys6:
            return KeyboardLayoutConfig(
                layout: layout,
                gridColumns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3),
                keyLetterGrouping: Constants.keyLetterGrouping6Keys,
                keys: createKeys(for: layout, grouping: Constants.keyLetterGrouping6Keys)
            )
        case .keys8:
            return KeyboardLayoutConfig(
                layout: layout,
                gridColumns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4),
                keyLetterGrouping: Constants.keyLetterGrouping8Keys,
                keys: createKeys(for: layout, grouping: Constants.keyLetterGrouping8Keys)
            )
        case .strokes2:
            return KeyboardLayoutConfig(
                layout: layout,
                gridColumns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3),
                keyLetterGrouping: Constants.keyLetterGroupingSteve,
                keys: createKeys(for: layout, grouping: Constants.keyLetterGroupingSteve)
            )
        case .msr:
            return KeyboardLayoutConfig(
                layout: layout,
                gridColumns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3),
                keyLetterGrouping: Constants.keyLetterGroupingMSR,
                keys: createMSRKeys()
            )
        }
    }
    
    private static func createKeys(for layout: KeyboardLayout, grouping: [String]) -> [KeyboardKey] {
        return grouping.enumerated().map { index, letters in
            KeyboardKey(
                index: index,
                text: letters.uppercased(),
                letters: letters,
                isSpecial: false,
                textColor: .white,
                backgroundColor: .clear
            )
        }
    }
    
    private static func createMSRKeys() -> [KeyboardKey] {
        return Constants.MSRKeyboardMasterKeys1.enumerated().map { index, text in
            let isSpecial = text.contains(Constants.MSRKeyYes) || text.contains(Constants.MSRKeyNo)
            return KeyboardKey(
                index: index,
                text: text,
                letters: "",
                isSpecial: isSpecial,
                textColor: isSpecial ? .red : .white,
                backgroundColor: .clear
            )
        }
    }
}

// MARK: - Main Keyboard View

/// SwiftUI implementation of the keyboard interface
struct KeyboardView: View {
    @StateObject private var viewModel: KeyboardViewModel
    @State private var keyboardConfig: KeyboardLayoutConfig
    @State private var highlightedKeyIndex: Int? = nil
    
    init(viewModel: KeyboardViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self._keyboardConfig = State(initialValue: KeyboardLayoutConfig.config(for: viewModel.keyboardLayout))
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Keyboard Grid
            LazyVGrid(columns: keyboardConfig.gridColumns, spacing: 8) {
                ForEach(keyboardConfig.keys) { key in
                    KeyView(
                        key: key,
                        isHighlighted: highlightedKeyIndex == key.index,
                        onTap: { handleKeyTap(key) },
                        onSwipe: { direction in handleKeySwipe(key, direction: direction) }
                    )
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(radius: 2)
        }
        .onChange(of: viewModel.keyboardLayout) { _, newLayout in
            withAnimation(.easeInOut(duration: 0.3)) {
                keyboardConfig = KeyboardLayoutConfig.config(for: newLayout)
            }
        }
        .onChange(of: viewModel.enteredKeys) { _, _ in
            updateKeyHighlighting()
        }
    }
    
    // MARK: - Private Methods
    
    private func handleKeyTap(_ key: KeyboardKey) {
        highlightKey(key.index)
        
        if keyboardConfig.layout == .msr {
            handleMSRKeyTap(key)
        } else if keyboardConfig.layout == .strokes2 {
            handleTwoStrokeKeyTap(key)
        } else {
            handleRegularKeyTap(key)
        }
    }
    
    private func handleKeySwipe(_ key: KeyboardKey, direction: SwipeDirection) {
        highlightKey(key.index)
        
        if keyboardConfig.layout == .msr {
            handleMSRKeySwipe(key, direction: direction)
        } else if keyboardConfig.layout == .strokes2 {
            handleTwoStrokeKeySwipe(key, direction: direction)
        } else {
            handleRegularKeySwipe(key, direction: direction)
        }
    }
    
    private func handleRegularKeyTap(_ key: KeyboardKey) {
        viewModel.keyEntered(key: key.index, isSwipe: false)
    }
    
    private func handleRegularKeySwipe(_ key: KeyboardKey, direction: SwipeDirection) {
        let swipeKeyIndex = SwipeDirection.keyIndex(for: direction, numberOfKeys: keyboardConfig.keys.count)
        viewModel.keyEntered(key: swipeKeyIndex, isSwipe: true)
    }
    
    private func handleTwoStrokeKeyTap(_ key: KeyboardKey) {
        if viewModel.isTwoStrokesMode {
            if viewModel.firstStroke == nil {
                viewModel.firstStrokeEntered(key: key.index, isSwipe: false)
            } else {
                viewModel.secondStrokeEntered(key: key.index, isSwipe: false)
            }
        } else {
            viewModel.keyEntered(key: key.index, isSwipe: false)
        }
    }
    
    private func handleTwoStrokeKeySwipe(_ key: KeyboardKey, direction: SwipeDirection) {
        let swipeKeyIndex = SwipeDirection.keyIndex(for: direction, numberOfKeys: keyboardConfig.keys.count)
        
        if viewModel.isTwoStrokesMode {
            if viewModel.firstStroke == nil {
                viewModel.firstStrokeEntered(key: swipeKeyIndex, isSwipe: true)
            } else {
                viewModel.secondStrokeEntered(key: swipeKeyIndex, isSwipe: true)
            }
        } else {
            viewModel.keyEntered(key: swipeKeyIndex, isSwipe: true)
        }
    }
    
    private func handleMSRKeyTap(_ key: KeyboardKey) {
        // MSR keyboard logic will be implemented based on current key state
        viewModel.msrKeyEntered(key: key.index, isSwipe: false)
    }
    
    private func handleMSRKeySwipe(_ key: KeyboardKey, direction: SwipeDirection) {
        let swipeKeyIndex = SwipeDirection.keyIndex(for: direction, numberOfKeys: keyboardConfig.keys.count)
        viewModel.msrKeyEntered(key: swipeKeyIndex, isSwipe: true)
    }
    
    private func highlightKey(_ index: Int) {
        highlightedKeyIndex = index
        
        // Remove highlight after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            highlightedKeyIndex = nil
        }
    }
    
    private func updateKeyHighlighting() {
        // Update key highlighting based on current state
        // This will be enhanced with more sophisticated highlighting logic
    }
}

// MARK: - Swipe Direction Enum

enum SwipeDirection: CaseIterable {
    case up, down, left, right
    
    static func keyIndex(for direction: SwipeDirection, numberOfKeys: Int) -> Int {
        // This implements the same logic as SwipeView.keyIndexForSwipe
        // For now, return a simple mapping - will be enhanced with proper angle calculation
        switch direction {
        case .up: return 0
        case .right: return 1
        case .left: return 2
        case .down: return 3
        }
    }
}

// MARK: - Preview

#Preview {
    KeyboardView(viewModel: KeyboardViewModel())
        .padding()
        .background(Color.gray.opacity(0.1))
}
