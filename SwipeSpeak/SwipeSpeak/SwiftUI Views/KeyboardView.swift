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
struct SwiftUIKeyboardKey: Identifiable, Hashable {
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
    let keys: [SwiftUIKeyboardKey]
    
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
    
    private static func createKeys(for layout: KeyboardLayout, grouping: [String]) -> [SwiftUIKeyboardKey] {
        return grouping.enumerated().map { index, letters in
            SwiftUIKeyboardKey(
                index: index,
                text: letters.uppercased(),
                letters: letters,
                isSpecial: false,
                textColor: .white,
                backgroundColor: .clear
            )
        }
    }
    
    private static func createMSRKeys() -> [SwiftUIKeyboardKey] {
        return Constants.MSRKeyboardMasterKeys1.enumerated().map { index, text in
            let isSpecial = text.contains(Constants.MSRKeyYes) || text.contains(Constants.MSRKeyNo)
            return SwiftUIKeyboardKey(
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
    @StateObject private var animationManager = AnimationStateManager()
    
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
                        onSwipe: { direction, velocity in handleKeySwipe(key, direction: direction, velocity: velocity) }
                    )
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(radius: 2)
        }
        .layoutTransition(isTransitioning: animationManager.isLayoutTransitioning)
        .onChange(of: viewModel.keyboardLayout) { _, newLayout in
            animationManager.startLayoutTransition()
            withAnimation(AnimationConfig.layoutTransition) {
                keyboardConfig = KeyboardLayoutConfig.config(for: newLayout)
            }
        }
        .onChange(of: viewModel.enteredKeys) { _, _ in
            updateKeyHighlighting()
        }
    }
    
    // MARK: - Private Methods
    
    private func handleKeyTap(_ key: SwiftUIKeyboardKey) {
        highlightKey(key.index)
        
        if keyboardConfig.layout == .msr {
            handleMSRKeyTap(key)
        } else if keyboardConfig.layout == .strokes2 {
            handleTwoStrokeKeyTap(key)
        } else {
            handleRegularKeyTap(key)
        }
    }
    
    private func handleKeySwipe(_ key: SwiftUIKeyboardKey, direction: SwipeDirection, velocity: CGSize) {
        highlightKey(key.index)

        if keyboardConfig.layout == .msr {
            handleMSRKeySwipe(key, direction: direction, velocity: velocity)
        } else if keyboardConfig.layout == .strokes2 {
            handleTwoStrokeKeySwipe(key, direction: direction, velocity: velocity)
        } else {
            handleRegularKeySwipe(key, direction: direction, velocity: velocity)
        }
    }
    
    private func handleRegularKeyTap(_ key: SwiftUIKeyboardKey) {
        viewModel.keyEntered(key.index, isSwipe: false)
    }

    private func handleRegularKeySwipe(_ key: SwiftUIKeyboardKey, direction: SwipeDirection, velocity: CGSize) {
        let swipeKeyIndex = SwipeDirection.keyIndex(for: velocity, numberOfKeys: keyboardConfig.keys.count)
        viewModel.keyEntered(swipeKeyIndex, isSwipe: true)
    }
    
    private func handleTwoStrokeKeyTap(_ key: SwiftUIKeyboardKey) {
        if viewModel.isTwoStrokesMode {
            if viewModel.firstStroke == nil {
                viewModel.firstStrokeEntered(key: key.index, isSwipe: false)
            } else {
                viewModel.secondStrokeEntered(key: key.index, isSwipe: false)
            }
        } else {
            viewModel.keyEntered(key.index, isSwipe: false)
        }
    }
    
    private func handleTwoStrokeKeySwipe(_ key: SwiftUIKeyboardKey, direction: SwipeDirection, velocity: CGSize) {
        let numberOfKeys: Int
        if viewModel.isTwoStrokesMode {
            if viewModel.firstStroke == nil {
                numberOfKeys = -1
            } else {
                if viewModel.firstStroke == 5 {
                    numberOfKeys = -3
                } else {
                    numberOfKeys = -2
                }
            }
        } else {
            numberOfKeys = keyboardConfig.keys.count
        }

        let swipeKeyIndex = SwipeDirection.keyIndex(for: velocity, numberOfKeys: numberOfKeys)

        if viewModel.isTwoStrokesMode {
            if viewModel.firstStroke == nil {
                viewModel.firstStrokeEntered(key: swipeKeyIndex, isSwipe: true)
            } else {
                viewModel.secondStrokeEntered(key: swipeKeyIndex, isSwipe: true)
            }
        } else {
            viewModel.keyEntered(swipeKeyIndex, isSwipe: true)
        }
    }
    
    private func handleMSRKeyTap(_ key: SwiftUIKeyboardKey) {
        // MSR keyboard logic will be implemented based on current key state
        viewModel.msrKeyEntered(key: key.index, isSwipe: false)
    }

    private func handleMSRKeySwipe(_ key: SwiftUIKeyboardKey, direction: SwipeDirection, velocity: CGSize) {
        let swipeKeyIndex = SwipeDirection.keyIndex(for: velocity, numberOfKeys: keyboardConfig.keys.count)
        viewModel.msrKeyEntered(key: swipeKeyIndex, isSwipe: true)
    }
    
    private func highlightKey(_ index: Int) {
        highlightedKeyIndex = index
        animationManager.highlightKey(index)

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

    /// Calculate key index based on velocity and number of keys, matching UIKit SwipeView logic
    static func keyIndex(for velocity: CGSize, numberOfKeys: Int) -> Int {
        var degree = Double(atan2(velocity.height, velocity.width)) * 180 / Double.pi
        if degree < 0 {
            degree += 360
        }

        if numberOfKeys == 4 {
            if (315 <= degree && degree <= 360) || (0 <= degree && degree < 45) {
                return 1
            } else if (45 <= degree && degree < 135) {
                return 3
            } else if (135 <= degree && degree < 225) {
                return 2
            } else if (225 <= degree && degree < 315) {
                return 0
            }
        } else if numberOfKeys == 6 {
            if (0 <= degree && degree < 60) {
                return 3
            } else if (60 <= degree && degree < 120) {
                return 4
            } else if (120 <= degree && degree < 180) {
                return 5
            } else if (180 <= degree && degree < 240) {
                return 2
            } else if (240 <= degree && degree < 300) {
                return 1
            } else if (300 <= degree && degree <= 360) {
                return 0
            }
        } else if numberOfKeys == 8 {
            if (337.5 <= degree && degree <= 360) || (0 <= degree && degree < 22.5) {
                return 3
            } else if (22.5 <= degree && degree < 67.5) {
                return 4
            } else if (67.5 <= degree && degree < 112.5) {
                return 5
            } else if (112.5 <= degree && degree < 157.5) {
                return 6
            } else if (157.5 <= degree && degree < 202.5) {
                return 7
            } else if (202.5 <= degree && degree < 247.5) {
                return 0
            } else if (247.5 <= degree && degree < 292.5) {
                return 1
            } else if (292.5 <= degree && degree < 337.5) {
                return 2
            }
        } else if numberOfKeys == -1 { // 6 directions for Steve keyboard layout, stroke 1
            if (0 <= degree && degree < 60) {
                return 3
            } else if (60 <= degree && degree < 120) {
                return 4
            } else if (120 <= degree && degree < 180) {
                return 5
            } else if (180 <= degree && degree < 240) {
                return 2
            } else if (240 <= degree && degree < 300) {
                return 1
            } else if (300 <= degree && degree <= 360) {
                return 0
            }
        } else if numberOfKeys == -2 { // 4 directions for Steve keyboard layout, stroke 2
            if (315 <= degree && degree <= 360) || (0 <= degree && degree < 45) {
                return 0
            } else if (45 <= degree && degree < 135) {
                return 3
            } else if (135 <= degree && degree < 225) {
                return 2
            } else if (225 <= degree && degree < 315) {
                return 1
            }
        } else if numberOfKeys == -3 { // 6 directions(include Y,Z) for Steve keyboard layout, stroke 2
            let unit = 22.5
            if (unit*14 <= degree && degree <= 360) || (0 <= degree && degree < unit) {
                return 0
            } else if (unit <= degree && degree < unit*3) {
                return 4
            } else if (unit*3 <= degree && degree < unit*5) {
                return 3
            } else if (unit*5 <= degree && degree < unit*7) {
                return 5
            } else if (unit*7 <= degree && degree < unit*10) {
                return 2
            } else if (unit*10 <= degree && degree < unit*14) {
                return 1
            }
        }
        return 0
    }

    /// Simple direction detection for basic swipe recognition
    static func direction(for velocity: CGSize) -> SwipeDirection {
        if abs(velocity.width) > abs(velocity.height) {
            return velocity.width > 0 ? .right : .left
        } else {
            return velocity.height > 0 ? .down : .up
        }
    }
}

// MARK: - Preview

#Preview {
    KeyboardView(viewModel: KeyboardViewModel())
        .padding()
        .background(Color.gray.opacity(0.1))
}
