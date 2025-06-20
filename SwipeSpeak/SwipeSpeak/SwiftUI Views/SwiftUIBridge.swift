//
//  SwiftUIBridge.swift
//  SwipeSpeak
//
//  Created by SwiftUI Migration on 20/01/2025.
//  Copyright © 2025 TeamGleason. All rights reserved.
//

import UIKit
import SwiftUI

/// Bridge class to integrate SwiftUI views into UIKit navigation
@MainActor
class SwiftUIBridge {

    /// Create a UIViewController hosting the SwiftUI SettingsView
    static func createSettingsViewController() -> UIViewController {
        let settingsView = SettingsView()
        let hostingController = UIHostingController(rootView: settingsView)

        // Configure the hosting controller
        hostingController.title = "Settings"
        hostingController.modalPresentationStyle = .formSheet

        return hostingController
    }

    /// Create a UIViewController hosting any SwiftUI view
    static func createHostingController<Content: View>(
        for view: Content,
        title: String? = nil,
        modalPresentationStyle: UIModalPresentationStyle = .automatic
    ) -> UIHostingController<Content> {
        let hostingController = UIHostingController(rootView: view)
        hostingController.title = title
        hostingController.modalPresentationStyle = modalPresentationStyle
        return hostingController
    }
    
    /// Present a SwiftUI view modally from a UIKit view controller
    static func presentSwiftUIView<Content: View>(
        _ view: Content,
        from presentingViewController: UIViewController,
        title: String? = nil,
        animated: Bool = true,
        completion: (() -> Void)? = nil
    ) {
        let hostingController = createHostingController(
            for: view,
            title: title,
            modalPresentationStyle: .formSheet
        )
        
        presentingViewController.present(
            hostingController,
            animated: animated,
            completion: completion
        )
    }
    
    /// Push a SwiftUI view onto a UIKit navigation stack
    static func pushSwiftUIView<Content: View>(
        _ view: Content,
        onto navigationController: UINavigationController,
        title: String? = nil,
        animated: Bool = true
    ) {
        let hostingController = createHostingController(
            for: view,
            title: title
        )
        
        navigationController.pushViewController(hostingController, animated: animated)
    }
}

// MARK: - UIViewController Extensions

extension UIViewController {
    
    /// Present the SwiftUI Settings view
    func presentSwiftUISettings(animated: Bool = true, completion: (() -> Void)? = nil) {
        let settingsViewController = SwiftUIBridge.createSettingsViewController()
        present(settingsViewController, animated: animated, completion: completion)
    }
    
    /// Present any SwiftUI view modally
    func presentSwiftUIView<Content: View>(
        _ view: Content,
        title: String? = nil,
        animated: Bool = true,
        completion: (() -> Void)? = nil
    ) {
        SwiftUIBridge.presentSwiftUIView(
            view,
            from: self,
            title: title,
            animated: animated,
            completion: completion
        )
    }
}

extension UINavigationController {
    
    /// Push a SwiftUI view onto the navigation stack
    func pushSwiftUIView<Content: View>(
        _ view: Content,
        title: String? = nil,
        animated: Bool = true
    ) {
        SwiftUIBridge.pushSwiftUIView(
            view,
            onto: self,
            title: title,
            animated: animated
        )
    }
}

// MARK: - SwiftUI Environment Extensions

/// Custom environment key for UIKit navigation
struct UIKitNavigationKey: EnvironmentKey {
    static let defaultValue: UINavigationController? = nil
}

extension EnvironmentValues {
    var uikitNavigation: UINavigationController? {
        get { self[UIKitNavigationKey.self] }
        set { self[UIKitNavigationKey.self] = newValue }
    }
}

/// Custom environment key for dismissing SwiftUI views in UIKit context
struct UIKitDismissKey: EnvironmentKey {
    static let defaultValue: (@Sendable () -> Void)? = nil
}

extension EnvironmentValues {
    var uikitDismiss: (@Sendable () -> Void)? {
        get { self[UIKitDismissKey.self] }
        set { self[UIKitDismissKey.self] = newValue }
    }
}

// MARK: - SwiftUI View Modifiers

extension View {
    
    /// Inject UIKit navigation controller into SwiftUI environment
    func withUIKitNavigation(_ navigationController: UINavigationController?) -> some View {
        self.environment(\.uikitNavigation, navigationController)
    }
    
    /// Inject UIKit dismiss action into SwiftUI environment
    func withUIKitDismiss(_ dismissAction: @escaping @Sendable () -> Void) -> some View {
        self.environment(\.uikitDismiss, dismissAction)
    }
    
    /// Configure for UIKit integration
    func configuredForUIKit(
        navigationController: UINavigationController? = nil,
        dismissAction: (@Sendable () -> Void)? = nil
    ) -> some View {
        self
            .withUIKitNavigation(navigationController)
            .withUIKitDismiss(dismissAction ?? {})
    }
}

// MARK: - Hybrid Navigation Helpers

/// Helper class for managing hybrid UIKit/SwiftUI navigation
@MainActor
class HybridNavigationManager {

    weak var navigationController: UINavigationController?

    init(navigationController: UINavigationController?) {
        self.navigationController = navigationController
    }

    /// Navigate to SwiftUI settings from UIKit
    func presentSettings(from viewController: UIViewController) {
        viewController.presentSwiftUISettings()
    }

    /// Navigate back to UIKit from SwiftUI
    func dismissToUIKit() {
        navigationController?.dismiss(animated: true)
    }

    /// Push SwiftUI view onto UIKit navigation stack
    func pushSwiftUIView<Content: View>(_ view: Content, title: String? = nil) {
        navigationController?.pushSwiftUIView(view, title: title)
    }

    /// Pop back to UIKit view
    func popToUIKit(animated: Bool = true) {
        navigationController?.popViewController(animated: animated)
    }
}

// MARK: - Migration Utilities

/// Utilities to help with the gradual migration from UIKit to SwiftUI
enum MigrationUtilities {
    
    /// Check if a view controller should use SwiftUI replacement
    static func shouldUseSwiftUIReplacement(for viewController: UIViewController.Type) -> Bool {
        // During migration, we can gradually enable SwiftUI replacements
        switch viewController {
        case is SettingsVC.Type:
            return UserDefaults.standard.bool(forKey: "useSwiftUISettings")
        default:
            return false
        }
    }
    
    /// Enable SwiftUI replacement for a specific view controller
    static func enableSwiftUIReplacement(for viewControllerType: String) {
        UserDefaults.standard.set(true, forKey: "useSwiftUI\(viewControllerType)")
    }
    
    /// Disable SwiftUI replacement for a specific view controller
    static func disableSwiftUIReplacement(for viewControllerType: String) {
        UserDefaults.standard.set(false, forKey: "useSwiftUI\(viewControllerType)")
    }
}

// MARK: - Preview Helpers

#if DEBUG
/// Helper for SwiftUI previews that need UIKit context
struct UIKitPreviewWrapper<Content: View>: UIViewControllerRepresentable {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    func makeUIViewController(context: Context) -> UIHostingController<Content> {
        UIHostingController(rootView: content)
    }
    
    func updateUIViewController(_ uiViewController: UIHostingController<Content>, context: Context) {
        uiViewController.rootView = content
    }
}
#endif
