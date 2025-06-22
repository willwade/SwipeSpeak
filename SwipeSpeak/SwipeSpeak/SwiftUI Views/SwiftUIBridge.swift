//
//  SwiftUIBridge.swift
//  SwipeSpeak
//
//  Created by SwiftUI Migration on 20/01/2025.
//  Copyright © 2025 TeamGleason. All rights reserved.
//

import UIKit
import SwiftUI

/// Simplified bridge for UIKit → SwiftUI integration
/// Only contains methods actually used by the app
@MainActor
class SwiftUIBridge {

    /// Create a UIViewController hosting the SwiftUI SettingsView
    static func createSettingsViewController() -> UIViewController {
        let settingsView = SettingsView()
        let hostingController = UIHostingController(rootView: settingsView)
        hostingController.title = "Settings"
        hostingController.modalPresentationStyle = .formSheet
        return hostingController
    }

    /// Create a UIViewController hosting the SwiftUI SentenceHistoryView
    static func createSentenceHistoryViewController() -> UIViewController {
        let sentenceHistoryView = SentenceHistoryView()
        let hostingController = UIHostingController(rootView: sentenceHistoryView)
        hostingController.title = "Sentence History"

        // Wrap in navigation controller for modal presentation
        let navigationController = UINavigationController(rootViewController: hostingController)
        navigationController.modalPresentationStyle = .formSheet
        return navigationController
    }

}
