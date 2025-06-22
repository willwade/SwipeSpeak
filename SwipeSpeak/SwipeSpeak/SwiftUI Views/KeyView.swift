//
//  KeyView.swift
//  SwipeSpeak
//
//  Created by SwiftUI Migration on 22/06/2025.
//  Copyright © 2025 TeamGleason. All rights reserved.
//

import SwiftUI

/// Individual keyboard key view with gesture support
struct KeyView: View {
    let key: SwiftUIKeyboardKey
    let isHighlighted: Bool
    let onTap: () -> Void
    let onSwipe: (SwipeDirection, CGSize) -> Void
    
    @State private var dragOffset: CGSize = .zero
    @State private var isPressed: Bool = false
    @State private var swipeDirection: SwipeDirection? = nil
    @StateObject private var hapticManager = HapticFeedbackManager.shared
    
    var body: some View {
        ZStack {
            // Key Background
            RoundedRectangle(cornerRadius: 8)
                .fill(keyBackgroundColor)
                .stroke(keyBorderColor, lineWidth: keyBorderWidth)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            
            // Key Text
            Text(key.text)
                .font(keyFont)
                .foregroundColor(key.textColor)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .minimumScaleFactor(0.5)
                .padding(8)
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: keyHeight, maxHeight: .infinity)
        .keyPress(isPressed: isPressed)
        .keyHighlight(isHighlighted: isHighlighted, type: .border)
        .swipeIndicator(direction: swipeDirection, isActive: swipeDirection != nil)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    handleDragChanged(value)
                }
                .onEnded { value in
                    handleDragEnded(value)
                }
        )
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
        .accessibilityAddTraits(.isButton)
    }
    
    // MARK: - Computed Properties
    
    private var keyBackgroundColor: Color {
        if isHighlighted {
            return .blue.opacity(0.3)
        } else if isPressed {
            return .gray.opacity(0.4)
        } else {
            // Use a light gray background for better text contrast
            return Color(.systemGray6)
        }
    }
    
    private var keyBorderColor: Color {
        if isHighlighted {
            return .blue
        } else {
            return .green
        }
    }
    
    private var keyBorderWidth: CGFloat {
        isHighlighted ? 3.0 : 1.0
    }
    
    private var keyFont: Font {
        // Adjust font size based on device and content
        if UIDevice.current.userInterfaceIdiom == .pad {
            return .system(size: 24, weight: .medium)
        } else {
            return .system(size: 18, weight: .medium)
        }
    }
    
    private var keyHeight: CGFloat {
        // Adjust height based on device
        if UIDevice.current.userInterfaceIdiom == .pad {
            return 80
        } else {
            return 60
        }
    }
    
    private var accessibilityLabel: String {
        if key.isSpecial {
            return "\(key.text) key"
        } else {
            return "Key with letters: \(key.letters.uppercased())"
        }
    }

    private var accessibilityHint: String {
        if key.isSpecial {
            return "Double tap to activate \(key.text)"
        } else {
            return "Double tap to select, or swipe in any direction for different letters"
        }
    }
    
    // MARK: - Gesture Handling
    
    private func handleDragChanged(_ value: DragGesture.Value) {
        print("🔍 KeyView: handleDragChanged called for key \(key.index) - translation: \(value.translation)")
        dragOffset = value.translation

        if !isPressed {
            isPressed = true
            print("🔍 KeyView: Key \(key.index) pressed")
            // Provide haptic feedback on initial press
            hapticManager.keyPress()
        }
    }
    
    private func handleDragEnded(_ value: DragGesture.Value) {
        defer {
            dragOffset = .zero
            isPressed = false
        }
        
        let translation = value.translation
        let velocity = value.velocity
        
        // Determine if this was a tap or swipe
        let dragDistance = sqrt(translation.width * translation.width + translation.height * translation.height)
        let velocityMagnitude = sqrt(velocity.width * velocity.width + velocity.height * velocity.height)
        
        // Thresholds for swipe detection
        let minimumSwipeDistance: CGFloat = 20
        let minimumSwipeVelocity: CGFloat = 100
        
        if dragDistance < minimumSwipeDistance && velocityMagnitude < minimumSwipeVelocity {
            // This was a tap
            print("🔍 KeyView: Tap detected on key \(key.index)")
            onTap()
        } else {
            // This was a swipe - determine direction and pass velocity
            let detectedDirection = determineSwipeDirection(translation: translation, velocity: velocity)
            print("🔍 KeyView: Swipe detected on key \(key.index) - direction: \(detectedDirection)")

            // Show swipe direction indicator
            swipeDirection = detectedDirection

            // Provide haptic feedback for swipe
            hapticManager.keySwipe()

            // Clear swipe indicator after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                swipeDirection = nil
            }

            onSwipe(detectedDirection, velocity)
        }
    }
    
    private func determineSwipeDirection(translation: CGSize, velocity: CGSize) -> SwipeDirection {
        // Use both translation and velocity to determine direction
        let combinedX = translation.width + velocity.width * 0.1
        let combinedY = translation.height + velocity.height * 0.1
        
        // Determine primary direction
        if abs(combinedX) > abs(combinedY) {
            return combinedX > 0 ? .right : .left
        } else {
            return combinedY > 0 ? .down : .up
        }
    }
}

// MARK: - Key Animation Modifiers

extension KeyView {
    /// Adds a pulse animation for key highlighting
    func pulseAnimation() -> some View {
        self.modifier(PulseAnimationModifier(isHighlighted: isHighlighted))
    }
}

struct PulseAnimationModifier: ViewModifier {
    let isHighlighted: Bool
    @State private var scale: CGFloat = 1.0
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .onChange(of: isHighlighted) { _, highlighted in
                if highlighted {
                    withAnimation(.easeInOut(duration: 0.1).repeatCount(2, autoreverses: true)) {
                        scale = 1.1
                    }
                } else {
                    scale = 1.0
                }
            }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        // Regular key
        KeyView(
            key: SwiftUIKeyboardKey(index: 0, text: "ABCDEF", letters: "abcdef"),
            isHighlighted: false,
            onTap: { print("Tapped") },
            onSwipe: { direction, velocity in print("Swiped \(direction) with velocity \(velocity)") }
        )

        // Highlighted key
        KeyView(
            key: SwiftUIKeyboardKey(index: 1, text: "GHIJKL", letters: "ghijkl"),
            isHighlighted: true,
            onTap: { print("Tapped") },
            onSwipe: { direction, velocity in print("Swiped \(direction) with velocity \(velocity)") }
        )

        // Special MSR key
        KeyView(
            key: SwiftUIKeyboardKey(
                index: 2,
                text: "G 👍🏻 F\nI    H",
                letters: "",
                isSpecial: true,
                textColor: .red
            ),
            isHighlighted: false,
            onTap: { print("Tapped") },
            onSwipe: { direction, velocity in print("Swiped \(direction) with velocity \(velocity)") }
        )
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}
