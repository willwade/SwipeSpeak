//
//  LocalizedStrings.swift
//  SwipeSpeak
//
//  Created by SwiftUI Migration on 2025-01-20.
//  Copyright © 2025 TeamGleason. All rights reserved.
//

import Foundation

/// Centralized localization system using modern String Catalog approach
/// Replaces NSLocalizedString calls with structured, type-safe localization
enum LocalizedStrings {
    
    // MARK: - Keyboard Layouts
    
    enum Keyboard {
        static let fourKeys = String(localized: "keyboard.layout.4keys", comment: "4-key keyboard layout option")
        static let sixKeys = String(localized: "keyboard.layout.6keys", comment: "6-key keyboard layout option")
        static let eightKeys = String(localized: "keyboard.layout.8keys", comment: "8-key keyboard layout option")
        static let twoStrokes = String(localized: "keyboard.layout.strokes2", comment: "2-stroke keyboard layout option")
        static let msr = String(localized: "keyboard.layout.msr", comment: "MSR keyboard layout option")
    }
    
    // MARK: - Directions
    
    enum Direction {
        static let up = String(localized: "direction.up", comment: "Up direction")
        static let down = String(localized: "direction.down", comment: "Down direction")
        static let left = String(localized: "direction.left", comment: "Left direction")
        static let right = String(localized: "direction.right", comment: "Right direction")
        static let upLeft = String(localized: "direction.up.left", comment: "Up-left direction")
        static let upRight = String(localized: "direction.up.right", comment: "Up-right direction")
        static let downLeft = String(localized: "direction.down.left", comment: "Down-left direction")
        static let downRight = String(localized: "direction.down.right", comment: "Down-right direction")
    }
    
    // MARK: - Placeholders
    
    enum Placeholder {
        static let sentence = String(localized: "placeholder.sentence", comment: "Sentence area placeholder")
        static let word = String(localized: "placeholder.word", comment: "Word area placeholder")
    }
    
    // MARK: - Buttons
    
    enum Button {
        static let add = String(localized: "button.add", comment: "Add button")
        static let cancel = String(localized: "button.cancel", comment: "Cancel button")
        static let done = String(localized: "button.done", comment: "Done button")
        static let ok = String(localized: "button.ok", comment: "OK button")
    }
    
    // MARK: - Settings
    
    enum Settings {
        static let title = String(localized: "settings.title", comment: "Settings screen title")
        static let about = String(localized: "settings.about", comment: "About section header")
        static let aboutSwipeSpeak = String(localized: "settings.about.swipespeak", comment: "About SwipeSpeak navigation link")
        static let acknowledgements = String(localized: "settings.acknowledgements", comment: "Acknowledgements navigation link")
        static let resetToDefaults = String(localized: "settings.reset.defaults", comment: "Reset to defaults button")
        static let chooseEmailApp = String(localized: "settings.email.choose", comment: "Choose email app dialog title")
        
        enum Cloud {
            static let sync = String(localized: "settings.cloud.sync", comment: "Cloud sync section header")
            static let enable = String(localized: "settings.cloud.enable", comment: "Enable cloud sync toggle")
            static let description = String(localized: "settings.cloud.description", comment: "Cloud sync description text")
        }
    }
    
    // MARK: - Tutorial
    
    enum Tutorial {
        static let title = String(localized: "tutorial.title", comment: "Tutorial dialog title")
        static let message = String(localized: "tutorial.message", comment: "Tutorial dialog message")
        static let show = String(localized: "tutorial.button.show", comment: "Show tutorial button")
        static let later = String(localized: "tutorial.button.later", comment: "Later button")
    }
    
    // MARK: - About
    
    enum About {
        static let title = String(localized: "about.title", comment: "About screen title")
        static let contactSupport = String(localized: "about.contact.support", comment: "Contact support button")
        static let appDescription = String(localized: "about.app.description", comment: "App description text")
        static let developer = String(localized: "about.developer", comment: "Developer credit")
        
        static func version(_ version: String, _ build: String) -> String {
            let format = String(localized: "about.version", comment: "Version string with version and build numbers")
            return String(format: format, version, build)
        }
    }
    
    // MARK: - Words
    
    enum Words {
        static let addTitle = String(localized: "words.add.title", comment: "Add word dialog title")
        static let addPlaceholder = String(localized: "words.add.placeholder", comment: "Add word text field placeholder")
        static let addMessage = String(localized: "words.add.message", comment: "Add word validation message")
    }
    
    // MARK: - Error
    
    enum Error {
        static let title = String(localized: "error.title", comment: "Error dialog title")
    }
    
    // MARK: - Accessibility
    
    enum Accessibility {
        static let speak = String(localized: "accessibility.speak", comment: "Speak accessibility action")
        static let speakSentence = String(localized: "accessibility.speak.sentence", comment: "Speak sentence accessibility label")
        
        enum Sentence {
            static let empty = String(localized: "accessibility.sentence.empty", comment: "Empty sentence accessibility label")
            static let hint = String(localized: "accessibility.sentence.hint", comment: "Sentence accessibility hint")
            
            static func label(_ text: String) -> String {
                let format = String(localized: "accessibility.sentence.label", comment: "Sentence accessibility label with text")
                return String(format: format, text)
            }
        }
        
        enum Word {
            static let empty = String(localized: "accessibility.word.empty", comment: "Empty word accessibility label")
            static let hint = String(localized: "accessibility.word.hint", comment: "Word accessibility hint")
            
            static func label(_ text: String) -> String {
                let format = String(localized: "accessibility.word.label", comment: "Word accessibility label with text")
                return String(format: format, text)
            }
        }
        
        enum Keyboard {
            static let keysHint = String(localized: "accessibility.keyboard.hint.keys", comment: "Keys keyboard accessibility hint")
            static let strokesHint = String(localized: "accessibility.keyboard.hint.strokes", comment: "Strokes keyboard accessibility hint")
            static let msrHint = String(localized: "accessibility.keyboard.hint.msr", comment: "MSR keyboard accessibility hint")
            
            static func label(_ count: Int) -> String {
                let format = String(localized: "accessibility.keyboard.label", comment: "Keyboard accessibility label with key count")
                return String(format: format, count)
            }
        }
    }
}
