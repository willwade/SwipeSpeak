//
//  BaseViewModel.swift
//  SwipeSpeak
//
//  Created by SwiftUI Optimization on 22/06/2025.
//  Copyright © 2025 TeamGleason. All rights reserved.
//

import Foundation
@preconcurrency import Combine
import SwiftUI
import AudioToolbox

/// Base class for all ViewModels to reduce code duplication
@MainActor
class BaseViewModel: ObservableObject {
    
    // MARK: - Common Properties
    
    /// Set of cancellables for Combine subscriptions
    internal var cancellables = Set<AnyCancellable>()
    
    /// Error state for operations
    @Published var errorMessage: String?
    
    /// Loading state for async operations
    @Published var isLoading: Bool = false
    
    // MARK: - Dependencies
    
    /// Shared user preferences
    internal let userPreferences: UserPreferences
    
    // MARK: - Initialization
    
    init(userPreferences: UserPreferences = UserPreferences.shared) {
        self.userPreferences = userPreferences
        setupCommonBindings()
        setupBindings()
    }
    
    // MARK: - Common Methods
    
    /// Set up common bindings - called automatically
    private func setupCommonBindings() {
        // Monitor user preferences changes
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.handleUserPreferencesChanged()
            }
            .store(in: &cancellables)
    }
    
    /// Override in subclasses for specific bindings
    internal func setupBindings() {
        // Override in subclasses
    }
    
    /// Handle user preferences changes - override in subclasses
    internal func handleUserPreferencesChanged() {
        // Override in subclasses if needed
    }
    
    /// Set error message with automatic clearing
    internal func setError(_ message: String, clearAfter delay: TimeInterval = 5.0) {
        errorMessage = message
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            if self?.errorMessage == message {
                self?.errorMessage = nil
            }
        }
    }
    
    /// Clear error message
    internal func clearError() {
        errorMessage = nil
    }
    
    /// Perform async operation with loading state
    internal func performAsyncOperation<T: Sendable>(_ operation: @escaping @Sendable () async throws -> T) async -> T? {
        isLoading = true
        defer { isLoading = false }

        do {
            return try await operation()
        } catch {
            setError(error.localizedDescription)
            return nil
        }
    }
    
    // Note: Cleanup is handled automatically by ARC
}

// MARK: - Common Extensions

extension BaseViewModel {
    
    /// Common haptic feedback
    internal func triggerHapticFeedback(_ type: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        guard userPreferences.vibrate else { return }
        
        let generator = UIImpactFeedbackGenerator(style: type)
        generator.impactOccurred()
    }
    
    /// Common audio feedback
    internal func triggerAudioFeedback() {
        guard userPreferences.audioFeedback else { return }
        
        // Play system sound
        AudioServicesPlaySystemSound(1104) // Keyboard click sound
    }
}

// MARK: - Common Protocols

/// Protocol for ViewModels that handle text input
@MainActor
protocol TextInputViewModel: AnyObject {
    var currentText: String { get set }
    func clearText()
    func appendText(_ text: String)
}

/// Protocol for ViewModels that handle predictions
@MainActor
protocol PredictionViewModel: AnyObject {
    var predictions: [String] { get set }
    func updatePredictions(_ newPredictions: [String])
    func clearPredictions()
}

/// Protocol for ViewModels that handle keyboard layouts
@MainActor
protocol KeyboardLayoutViewModel: AnyObject {
    var keyboardLayout: KeyboardLayout { get set }
    func updateKeyboardLayout(_ layout: KeyboardLayout)
}
