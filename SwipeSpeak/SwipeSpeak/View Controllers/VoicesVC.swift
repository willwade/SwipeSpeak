//
//  VoicesVC.swift
//  SwipeSpeak
//
//  Created by Daniel Tsirulnikov on 05/11/2017.
//  Copyright © 2017 TeamGleason. All rights reserved.
//

import UIKit
import AVFoundation

class VoicesVC: UITableViewController {

    private lazy var englishVoices: [AVSpeechSynthesisVoice] = {
        let allVoices = AVSpeechSynthesisVoice.speechVoices().filter { voice in
            return voice.language.hasPrefix("en-")
        }

        // Sort voices to prioritize higher quality voices
        return allVoices.sorted { voice1, voice2 in
            // Prioritize enhanced/neural voices (iOS 15+)
            if #available(iOS 15.0, *) {
                let voice1Quality = voice1.quality
                let voice2Quality = voice2.quality

                if voice1Quality != voice2Quality {
                    return voice1Quality.rawValue > voice2Quality.rawValue
                }
            }

            // Then sort by name for consistency
            return voice1.name < voice2.name
        }
    }()
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return englishVoices.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return NSLocalizedString("English Voices", comment: "")
        }
        
        return nil
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "voiceCell", for: indexPath)

        let voice = englishVoices[indexPath.row]

        // Enhanced voice name with quality indicator
        var voiceName = voice.name
        if #available(iOS 15.0, *) {
            switch voice.quality {
            case .enhanced:
                voiceName += " (Enhanced)"
            case .premium:
                voiceName += " (Premium)"
            default:
                break
            }
        }

        cell.textLabel?.text = voiceName
        cell.detailTextLabel?.text = Locale.current.localizedString(forIdentifier: voice.language)

        if let voiceIdentifier = UserPreferences.shared.voiceIdentifier, voiceIdentifier == voice.identifier {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let voice = englishVoices[indexPath.row]

        UserPreferences.shared.voiceIdentifier = voice.identifier
        
        SpeechSynthesizer.shared.speak(NSLocalizedString("Hello, this is \(voice.name).", comment: ""), voice.identifier)
        
        for cell in tableView.visibleCells {
            if tableView.indexPath(for: cell) == indexPath {
                cell.accessoryType = .checkmark
            } else {
                cell.accessoryType = .none
            }
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}
