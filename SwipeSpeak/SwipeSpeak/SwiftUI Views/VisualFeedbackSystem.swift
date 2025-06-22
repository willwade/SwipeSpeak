//
//  VisualFeedbackSystem.swift
//  SwipeSpeak
//
//  Created by SwiftUI Migration on 22/06/2025.
//  Copyright © 2025 TeamGleason. All rights reserved.
//

import SwiftUI
import UIKit

// MARK: - Haptic Feedback Manager

/// Centralized haptic feedback management for SwiftUI components
@MainActor
class HapticFeedbackManager: ObservableObject {
    static let shared = HapticFeedbackManager()
    
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let selection = UISelectionFeedbackGenerator()
    private let notification = UINotificationFeedbackGenerator()
    
    private init() {
        // Prepare generators for better performance
        prepareGenerators()
    }
    
    private func prepareGenerators() {
        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
        selection.prepare()
        notification.prepare()
    }
    
    /// Trigger haptic feedback for key press
    func keyPress() {
        guard UserPreferences.shared.vibrate else { return }
        impactLight.impactOccurred()
    }
    
    /// Trigger haptic feedback for key swipe
    func keySwipe() {
        guard UserPreferences.shared.vibrate else { return }
        impactMedium.impactOccurred()
    }
    
    /// Trigger haptic feedback for key selection
    func keySelection() {
        guard UserPreferences.shared.vibrate else { return }
        selection.selectionChanged()
    }
    
    /// Trigger haptic feedback for word completion
    func wordCompletion() {
        guard UserPreferences.shared.vibrate else { return }
        notification.notificationOccurred(.success)
    }
    
    /// Trigger haptic feedback for error
    func error() {
        guard UserPreferences.shared.vibrate else { return }
        notification.notificationOccurred(.error)
    }
    
    /// Trigger haptic feedback for warning
    func warning() {
        guard UserPreferences.shared.vibrate else { return }
        notification.notificationOccurred(.warning)
    }
}

// MARK: - Animation Configurations

/// Animation configurations for different feedback types
struct AnimationConfig {
    static let keyPress = Animation.easeInOut(duration: 0.1)
    static let keyHighlight = Animation.easeInOut(duration: 0.2)
    static let keySwipe = Animation.spring(response: 0.3, dampingFraction: 0.6)
    static let layoutTransition = Animation.easeInOut(duration: 0.3)
    static let pulse = Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true)
}

// MARK: - Visual Feedback Modifiers

/// Key highlighting animation modifier
struct KeyHighlightModifier: ViewModifier {
    let isHighlighted: Bool
    let animationType: HighlightType
    
    enum HighlightType {
        case border, glow, pulse, scale
    }
    
    func body(content: Content) -> some View {
        switch animationType {
        case .border:
            content
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.blue, lineWidth: isHighlighted ? 3 : 0)
                        .animation(AnimationConfig.keyHighlight, value: isHighlighted)
                )
        case .glow:
            content
                .shadow(
                    color: isHighlighted ? .blue : .clear,
                    radius: isHighlighted ? 8 : 0
                )
                .animation(AnimationConfig.keyHighlight, value: isHighlighted)
        case .pulse:
            content
                .scaleEffect(isHighlighted ? 1.05 : 1.0)
                .animation(
                    isHighlighted ? AnimationConfig.pulse : AnimationConfig.keyHighlight,
                    value: isHighlighted
                )
        case .scale:
            content
                .scaleEffect(isHighlighted ? 1.1 : 1.0)
                .animation(AnimationConfig.keyHighlight, value: isHighlighted)
        }
    }
}

/// Key press animation modifier
struct KeyPressModifier: ViewModifier {
    let isPressed: Bool
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .brightness(isPressed ? -0.1 : 0.0)
            .animation(AnimationConfig.keyPress, value: isPressed)
    }
}

/// Swipe direction indicator modifier
struct SwipeDirectionIndicator: ViewModifier {
    let direction: SwipeDirection?
    let isActive: Bool
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if let direction = direction, isActive {
                        directionArrow(for: direction)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            )
    }
    
    @ViewBuilder
    private func directionArrow(for direction: SwipeDirection) -> some View {
        Image(systemName: arrowIcon(for: direction))
            .font(.title2)
            .foregroundColor(.blue)
            .offset(arrowOffset(for: direction))
            .animation(AnimationConfig.keySwipe, value: direction)
    }
    
    private func arrowIcon(for direction: SwipeDirection) -> String {
        switch direction {
        case .up: return "arrow.up"
        case .down: return "arrow.down"
        case .left: return "arrow.left"
        case .right: return "arrow.right"
        }
    }
    
    private func arrowOffset(for direction: SwipeDirection) -> CGSize {
        let offset: CGFloat = 15
        switch direction {
        case .up: return CGSize(width: 0, height: -offset)
        case .down: return CGSize(width: 0, height: offset)
        case .left: return CGSize(width: -offset, height: 0)
        case .right: return CGSize(width: offset, height: 0)
        }
    }
}

/// Keyboard layout transition modifier
struct LayoutTransitionModifier: ViewModifier {
    let isTransitioning: Bool
    
    func body(content: Content) -> some View {
        content
            .opacity(isTransitioning ? 0.7 : 1.0)
            .scaleEffect(isTransitioning ? 0.95 : 1.0)
            .animation(AnimationConfig.layoutTransition, value: isTransitioning)
    }
}

// MARK: - View Extensions

extension View {
    /// Apply key highlighting animation
    func keyHighlight(isHighlighted: Bool, type: KeyHighlightModifier.HighlightType = .border) -> some View {
        self.modifier(KeyHighlightModifier(isHighlighted: isHighlighted, animationType: type))
    }
    
    /// Apply key press animation
    func keyPress(isPressed: Bool) -> some View {
        self.modifier(KeyPressModifier(isPressed: isPressed))
    }
    
    /// Apply swipe direction indicator
    func swipeIndicator(direction: SwipeDirection?, isActive: Bool = true) -> some View {
        self.modifier(SwipeDirectionIndicator(direction: direction, isActive: isActive))
    }
    
    /// Apply layout transition animation
    func layoutTransition(isTransitioning: Bool) -> some View {
        self.modifier(LayoutTransitionModifier(isTransitioning: isTransitioning))
    }
    
    /// Apply haptic feedback on tap
    func hapticFeedback(on action: @escaping () -> Void, type: HapticFeedbackType = .keyPress) -> some View {
        self.onTapGesture {
            switch type {
            case .keyPress:
                HapticFeedbackManager.shared.keyPress()
            case .keySwipe:
                HapticFeedbackManager.shared.keySwipe()
            case .selection:
                HapticFeedbackManager.shared.keySelection()
            case .wordCompletion:
                HapticFeedbackManager.shared.wordCompletion()
            case .error:
                HapticFeedbackManager.shared.error()
            case .warning:
                HapticFeedbackManager.shared.warning()
            }
            action()
        }
    }
}

// MARK: - Haptic Feedback Types

enum HapticFeedbackType {
    case keyPress, keySwipe, selection, wordCompletion, error, warning
}

// MARK: - Performance Optimized Animation States

/// Manages animation states for optimal performance
@MainActor
class AnimationStateManager: ObservableObject {
    @Published var highlightedKeys: Set<Int> = []
    @Published var pressedKeys: Set<Int> = []
    @Published var swipeDirection: SwipeDirection?
    @Published var isLayoutTransitioning: Bool = false
    
    private var highlightTimers: [Int: Timer] = [:]
    
    /// Highlight a key temporarily
    func highlightKey(_ keyIndex: Int, duration: TimeInterval = 0.3) {
        highlightedKeys.insert(keyIndex)
        
        // Cancel existing timer for this key
        highlightTimers[keyIndex]?.invalidate()
        
        // Set new timer to remove highlight
        highlightTimers[keyIndex] = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { _ in
            Task { @MainActor in
                self.highlightedKeys.remove(keyIndex)
                self.highlightTimers.removeValue(forKey: keyIndex)
            }
        }
    }
    
    /// Set key pressed state
    func setKeyPressed(_ keyIndex: Int, isPressed: Bool) {
        if isPressed {
            pressedKeys.insert(keyIndex)
        } else {
            pressedKeys.remove(keyIndex)
        }
    }
    
    /// Show swipe direction temporarily
    func showSwipeDirection(_ direction: SwipeDirection, duration: TimeInterval = 0.5) {
        swipeDirection = direction
        
        Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { _ in
            Task { @MainActor in
                self.swipeDirection = nil
            }
        }
    }
    
    /// Start layout transition
    func startLayoutTransition(duration: TimeInterval = 0.3) {
        isLayoutTransitioning = true
        
        Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { _ in
            Task { @MainActor in
                self.isLayoutTransitioning = false
            }
        }
    }
    
    /// Clear all animation states
    func clearAllStates() {
        highlightedKeys.removeAll()
        pressedKeys.removeAll()
        swipeDirection = nil
        isLayoutTransitioning = false
        
        // Cancel all timers
        highlightTimers.values.forEach { $0.invalidate() }
        highlightTimers.removeAll()
    }
}

// MARK: - Performance Optimization

/// Performance monitor for animation system
@MainActor
class AnimationPerformanceMonitor: ObservableObject {
    @Published var frameRate: Double = 60.0
    @Published var isOptimized: Bool = true

    private var lastFrameTime: CFTimeInterval = 0
    private var frameCount: Int = 0
    private var frameRateHistory: [Double] = []

    func recordFrame() {
        let currentTime = CACurrentMediaTime()

        if lastFrameTime > 0 {
            let frameDuration = currentTime - lastFrameTime
            let currentFrameRate = 1.0 / frameDuration

            frameRateHistory.append(currentFrameRate)
            if frameRateHistory.count > 60 { // Keep last 60 frames
                frameRateHistory.removeFirst()
            }

            frameRate = frameRateHistory.reduce(0, +) / Double(frameRateHistory.count)
            isOptimized = frameRate >= 55.0 // Consider optimized if above 55fps
        }

        lastFrameTime = currentTime
        frameCount += 1
    }

    func reset() {
        frameRateHistory.removeAll()
        frameCount = 0
        lastFrameTime = 0
    }
}

/// Optimized animation preferences
struct AnimationPreferences {
    @MainActor static var reduceMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    @MainActor static var prefersCrossFadeTransitions: Bool {
        UIAccessibility.prefersCrossFadeTransitions
    }

    @MainActor static func optimizedAnimation<V: Equatable>(_ animation: Animation, value: V) -> Animation {
        if reduceMotion {
            return .linear(duration: 0.1)
        }
        return animation
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        // Key highlight examples
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .frame(width: 80, height: 60)
            .keyHighlight(isHighlighted: true, type: .border)
            .overlay(Text("Border"))

        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .frame(width: 80, height: 60)
            .keyHighlight(isHighlighted: true, type: .glow)
            .overlay(Text("Glow"))

        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .frame(width: 80, height: 60)
            .keyPress(isPressed: true)
            .overlay(Text("Pressed"))

        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .frame(width: 80, height: 60)
            .swipeIndicator(direction: .right)
            .overlay(Text("Swipe"))
    }
    .padding()
}
