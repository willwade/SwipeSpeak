//
//  SpeechSynthesizer.swift
//  SwipeSpeak
//
//  Created by Daniel Tsirulnikov on 09/11/2017.
//  Copyright © 2017 Microsoft. All rights reserved.
//

import Foundation
import AVFoundation

class SpeechSynthesizer {
    
    @MainActor static let shared = SpeechSynthesizer()

    private let synthesizer = AVSpeechSynthesizer()

    private init() { }
    
    @MainActor func speak(_ text: String) {
        speak(text, UserPreferences.shared.voiceIdentifier)
    }

    @MainActor func speak(_ text: String, _ voiceIdentifier: String? = nil) {
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
    
}
