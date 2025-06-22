//
//  CommonUIComponents.swift
//  SwipeSpeak
//
//  Created by SwiftUI Optimization on 22/06/2025.
//  Copyright © 2025 TeamGleason. All rights reserved.
//

import SwiftUI

// MARK: - Common Button Styles

/// Standard button style for SwipeSpeak
struct SwipeSpeakButtonStyle: ButtonStyle {
    let isDestructive: Bool
    let isSecondary: Bool
    
    init(isDestructive: Bool = false, isSecondary: Bool = false) {
        self.isDestructive = isDestructive
        self.isSecondary = isSecondary
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.medium))
            .foregroundColor(foregroundColor(configuration))
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(backgroundColor(configuration))
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
    
    private func foregroundColor(_ configuration: Configuration) -> Color {
        if isDestructive {
            return .white
        } else if isSecondary {
            return .primary
        } else {
            return .white
        }
    }
    
    private func backgroundColor(_ configuration: Configuration) -> Color {
        let baseColor: Color
        
        if isDestructive {
            baseColor = .red
        } else if isSecondary {
            baseColor = Color(.systemGray5)
        } else {
            baseColor = .blue
        }
        
        return configuration.isPressed ? baseColor.opacity(0.8) : baseColor
    }
}

// MARK: - Common Text Styles

/// Standard text display style for SwipeSpeak
struct SwipeSpeakTextStyle: ViewModifier {
    let style: TextStyle
    let isHighlighted: Bool
    
    enum TextStyle {
        case sentence
        case word
        case prediction
        case label
    }
    
    func body(content: Content) -> some View {
        content
            .font(font)
            .foregroundColor(foregroundColor)
            .padding(padding)
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
    }
    
    private var font: Font {
        switch style {
        case .sentence:
            return .title2.weight(.medium)
        case .word:
            return .title3.weight(.medium)
        case .prediction:
            return .body
        case .label:
            return .caption
        }
    }
    
    private var foregroundColor: Color {
        isHighlighted ? .white : .primary
    }
    
    private var backgroundColor: Color {
        switch style {
        case .sentence, .word:
            return isHighlighted ? .blue : Color(.systemGray6)
        case .prediction:
            return isHighlighted ? .blue : Color(.systemBackground)
        case .label:
            return .clear
        }
    }
    
    private var borderColor: Color {
        isHighlighted ? .blue : Color(.systemGray4)
    }
    
    private var borderWidth: CGFloat {
        isHighlighted ? 2 : 1
    }
    
    private var padding: EdgeInsets {
        switch style {
        case .sentence, .word:
            return EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
        case .prediction:
            return EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
        case .label:
            return EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
        }
    }
    
    private var cornerRadius: CGFloat {
        switch style {
        case .sentence, .word:
            return 12
        case .prediction:
            return 8
        case .label:
            return 4
        }
    }
}

// MARK: - Common Accessibility Helpers

/// Standard accessibility configuration for SwipeSpeak components
struct SwipeSpeakAccessibility {
    
    /// Generate accessibility label for keyboard keys
    static func keyboardKeyLabel(text: String, index: Int, layout: KeyboardLayout) -> String {
        switch layout {
        case .keys4:
            return "Key \(index + 1) of 4: \(text)"
        case .keys6:
            return "Key \(index + 1) of 6: \(text)"
        case .keys8:
            return "Key \(index + 1) of 8: \(text)"
        case .strokes2:
            return "Two-stroke key \(index + 1): \(text)"
        case .msr:
            return "MSR key \(index + 1): \(text)"
        }
    }
    
    /// Generate accessibility hint for keyboard keys
    static func keyboardKeyHint(layout: KeyboardLayout) -> String {
        switch layout {
        case .keys4, .keys6, .keys8:
            return "Tap to select letters, swipe in different directions for more options"
        case .strokes2:
            return "First tap selects direction, second tap selects letter"
        case .msr:
            return "Tap to switch between master and detail keys"
        }
    }
    
    /// Generate accessibility label for text displays
    static func textDisplayLabel(text: String, type: String, isEmpty: Bool) -> String {
        if isEmpty {
            return "Empty \(type) area"
        } else {
            return "\(type): \(text)"
        }
    }
    
    /// Generate accessibility hint for text displays
    static func textDisplayHint(type: String, isHighlighted: Bool) -> String {
        if isHighlighted {
            return "Tap to add \(type) to sentence, long press for options"
        } else {
            return "Tap to highlight \(type), long press for options"
        }
    }
}

// MARK: - Common Animation Configurations

/// Standard animation configurations for SwipeSpeak
struct SwipeSpeakAnimations {
    
    /// Quick feedback animation
    static let quickFeedback = Animation.easeInOut(duration: 0.1)
    
    /// Standard UI animation
    static let standard = Animation.easeInOut(duration: 0.3)
    
    /// Layout transition animation
    static let layoutTransition = Animation.easeInOut(duration: 0.5)
    
    /// Bounce animation for highlights
    static let bounce = Animation.interpolatingSpring(stiffness: 300, damping: 15)
    
    /// Gentle fade animation
    static let fade = Animation.easeInOut(duration: 0.2)
}

// MARK: - View Extensions

extension View {
    
    /// Apply SwipeSpeak button style
    func swipeSpeakButton(isDestructive: Bool = false, isSecondary: Bool = false) -> some View {
        self.buttonStyle(SwipeSpeakButtonStyle(isDestructive: isDestructive, isSecondary: isSecondary))
    }
    
    /// Apply SwipeSpeak text style
    func swipeSpeakText(style: SwipeSpeakTextStyle.TextStyle, isHighlighted: Bool = false) -> some View {
        self.modifier(SwipeSpeakTextStyle(style: style, isHighlighted: isHighlighted))
    }
    
    /// Apply standard accessibility configuration
    func swipeSpeakAccessibility(label: String, hint: String? = nil, traits: AccessibilityTraits = []) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(traits)
    }
}
