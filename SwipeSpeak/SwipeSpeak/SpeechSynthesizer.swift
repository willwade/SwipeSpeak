//
//  SpeechSynthesizer.swift
//  SwipeSpeak
//
//  Created by Daniel Tsirulnikov on 09/11/2017.
//  Copyright © 2017 Microsoft. All rights reserved.
//

import Foundation
import AVFoundation
import Combine

@MainActor
class SpeechSynthesizer: NSObject, ObservableObject {

    static let shared = SpeechSynthesizer()

    private let synthesizer = AVSpeechSynthesizer()

    // Published properties for SwiftUI integration
    @Published var isSpeaking: Bool = false
    @Published var isPaused: Bool = false

    override init() {
        super.init()
        synthesizer.delegate = self
    }
    
    func speak(_ text: String) {
        speak(text, UserPreferences.shared.voiceIdentifier)
    }

    func speak(_ text: String, _ voiceIdentifier: String? = nil) {
        let utterance = AVSpeechUtterance(string: text)

        if let voiceIdentifier = voiceIdentifier,
            let voice = AVSpeechSynthesisVoice(identifier: voiceIdentifier) {
            utterance.voice = voice
        } else {
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        }

        utterance.rate = UserPreferences.shared.speechRate
        utterance.volume = UserPreferences.shared.speechVolume

        synthesizer.stopSpeaking(at: .immediate)
        synthesizer.speak(utterance)
    }

    /// Speak text asynchronously and wait for completion
    /// - Parameters:
    ///   - text: The text to speak
    ///   - voiceIdentifier: Optional voice identifier
    /// - Returns: True if speech completed successfully, false if interrupted
    func speakAsync(_ text: String, _ voiceIdentifier: String? = nil) async -> Bool {
        return await withCheckedContinuation { continuation in
            let utterance = AVSpeechUtterance(string: text)

            if let voiceIdentifier = voiceIdentifier,
                let voice = AVSpeechSynthesisVoice(identifier: voiceIdentifier) {
                utterance.voice = voice
            } else {
                utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            }

            utterance.rate = UserPreferences.shared.speechRate
            utterance.volume = UserPreferences.shared.speechVolume

            // Store continuation for completion callback
            speechCompletionContinuation = continuation

            synthesizer.stopSpeaking(at: .immediate)
            synthesizer.speak(utterance)
        }
    }

    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    func pauseSpeaking() {
        synthesizer.pauseSpeaking(at: .immediate)
    }

    func continueSpeaking() {
        synthesizer.continueSpeaking()
    }

    // Private property to store async continuation
    private var speechCompletionContinuation: CheckedContinuation<Bool, Never>?
}

// MARK: - AVSpeechSynthesizerDelegate
extension SpeechSynthesizer: @preconcurrency AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = true
            self.isPaused = false
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
            self.isPaused = false
            self.speechCompletionContinuation?.resume(returning: true)
            self.speechCompletionContinuation = nil
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
            self.isPaused = false
            self.speechCompletionContinuation?.resume(returning: false)
            self.speechCompletionContinuation = nil
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isPaused = true
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isPaused = false
        }
    }
}
