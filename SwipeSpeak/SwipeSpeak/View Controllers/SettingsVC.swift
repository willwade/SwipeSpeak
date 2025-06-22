//
//  SettingsVC.swift
//  SwipeSpeak
//
//  Created by Xiaoyi Zhang on 7/5/17.
//  Updated by Daniel Tsirulnikov on 11/9/17.
//  Copyright © 2017 TeamGleason. All rights reserved.
//

import Foundation
import UIKit
import SafariServices

class SettingsVC: UITableViewController {
    
    @IBOutlet weak var keyboardLayoutLabel: UILabel!
    @IBOutlet weak var predictionEngineLabel: UILabel!

    @IBOutlet weak var announceLettersCountSwitch: UISwitch!
    @IBOutlet weak var vibrateSwitch: UISwitch!

    @IBOutlet weak var longerPauseBetweenLettersSwitch: UISwitch!

    @IBOutlet weak var enableAudioFeedbackSwitch: UISwitch!
    @IBOutlet weak var enableCouldSyncSwitch: UISwitch!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Ensure proper safe area handling for the table view
        if #available(iOS 11.0, *) {
            tableView.contentInsetAdjustmentBehavior = .automatic
        }

        // Force navigation bar to respect safe area
        navigationController?.navigationBar.prefersLargeTitles = false
        extendedLayoutIncludesOpaqueBars = false
        edgesForExtendedLayout = []

        // Ensure proper background color
        view.backgroundColor = UIColor.systemGroupedBackground
        tableView.backgroundColor = UIColor.systemGroupedBackground
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Ensure navigation bar is properly configured
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.barStyle = .default

        keyboardLayoutLabel?.text = UserPreferences.shared.keyboardLayout.localizedString()

        // Update prediction engine label
        if let engineTypeString = UserPreferences.shared.predictionEngineType {
            predictionEngineLabel?.text = engineTypeString
        } else {
            predictionEngineLabel?.text = "custom"
        }

        announceLettersCountSwitch?.isOn = UserPreferences.shared.announceLettersCount
        vibrateSwitch?.isOn = UserPreferences.shared.vibrate

        longerPauseBetweenLettersSwitch?.isOn = UserPreferences.shared.longerPauseBetweenLetters

        enableAudioFeedbackSwitch?.isOn = UserPreferences.shared.audioFeedback
        enableCouldSyncSwitch?.isOn = UserPreferences.shared.enableCloudSync
    }
    
    @IBAction func dismissViewController() {
        dismiss(animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // Reload the image for the tint to take effect
        cell.imageView?.tintColor = UIColor.lightGray
        cell.imageView?.image = cell.imageView?.image?.withRenderingMode(.alwaysTemplate)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 && indexPath.row == 1 {
            showPredictionEngineSelection()
        } else if indexPath.section == 5 && indexPath.row == 2 {
            askToClearWordRanking()
        } else if indexPath.section == 6 && indexPath.row == 0 {
            showTutorial()
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    private func showTutorial() {
        present(SFSafariViewController(url: Constants.tutorialURL), animated: true, completion: nil)
    }

    private func showPredictionEngineSelection() {
        let alertController = UIAlertController(
            title: NSLocalizedString("Prediction Engine", comment: ""),
            message: NSLocalizedString("Choose the word prediction engine to use", comment: ""),
            preferredStyle: .actionSheet
        )

        // let manager = PredictionEngineManager.shared // Temporarily commented out

        for engineType in ["custom", "native"] { // Temporarily simplified
            let action = UIAlertAction(title: engineType, style: .default) { _ in
                Task { @MainActor in
                    // Temporarily simplified - just update the preference
                    UserPreferences.shared.predictionEngineType = engineType
                    self.predictionEngineLabel?.text = engineType

                    // Show brief description
                    let successAlert = UIAlertController(
                        title: NSLocalizedString("Engine Changed", comment: ""),
                        message: engineType,
                        preferredStyle: .alert
                    )
                    successAlert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default))
                    self.present(successAlert, animated: true)
                }
            }

            // Mark current engine
            if let currentType = UserPreferences.shared.predictionEngineType,
               currentType == engineType {
                action.setValue(true, forKey: "checked")
            }

            alertController.addAction(action)
        }

        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel))

        // For iPad
        if let popover = alertController.popoverPresentationController {
            popover.sourceView = predictionEngineLabel ?? view
            popover.sourceRect = predictionEngineLabel?.bounds ?? view.bounds
        }

        present(alertController, animated: true)
    }
    
    private func askToClearWordRanking() {
        let alertController = UIAlertController(title: NSLocalizedString("Clear Word Ranking", comment: ""),
                                                message: NSLocalizedString("Are you sure you want to clear the world ranking?", comment: ""),
                                                preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel)
        let clearAction = UIAlertAction(title: NSLocalizedString("Clear", comment: ""), style: .destructive) { (action: UIAlertAction) in
            UserPreferences.shared.clearWordRating()
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(clearAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func switchValueChanged(_ sender: UISwitch) {
        if sender === announceLettersCountSwitch {
            UserPreferences.shared.announceLettersCount = sender.isOn
        } else if sender === vibrateSwitch {
            UserPreferences.shared.vibrate = sender.isOn
        } else if sender === longerPauseBetweenLettersSwitch {
            UserPreferences.shared.longerPauseBetweenLetters = sender.isOn
        } else if sender === enableAudioFeedbackSwitch {
            UserPreferences.shared.audioFeedback = sender.isOn
        } else if sender === enableCouldSyncSwitch {
            UserPreferences.shared.enableCloudSync = sender.isOn
        }
    }
    
}
