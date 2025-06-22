//
//  ViewController.swift
//  SwipeSpeak
//
//  Created by Xiaoyi Zhang on 7/5/17.
//  Updated by Daniel Tsirulnikov on 11/9/17.
//  Copyright © 2017 TeamGleason. All rights reserved.
//

import UIKit
import AVFoundation
import SwiftUI
import Combine

class MainTVC: UITableViewController {
    
    // MARK: Constants
    
    nonisolated private static let wordAndFrequencyList: [(String, Int)] = {
        guard let path = Bundle.main.path(forResource: "word_frequency_english_ucrel", ofType: "csv"),
              let list = getWordAndFrequencyListFromCSV(path) else {
            print("Warning: Could not load word frequency list, using empty list")
            return []
        }
        return list
    }()
    private static let buildWordButtonText = NSLocalizedString("Build Word", comment: "")
    
    // MARK: - Properties
    
    private var viewDidAppear = false
    private var changedLabelFonts = false

    // Keys
    private var swipeView: SwipeView!

    var currentKeys = [String]()

    @IBOutlet var keysView4Keys: UIView!
    @IBOutlet var keysView6Keys: UIView!
    @IBOutlet var keysView8Keys: UIView!
    @IBOutlet var keysView2Strokes: UIView!
    @IBOutlet var keyboardMSMaster: UIView!

    @IBOutlet weak var sentenceLabel: UILabel!
    @IBOutlet weak var wordLabel: UILabel!
    
    @IBOutlet weak var sentencePlaceholderTF: UITextField!
    @IBOutlet weak var wordPlaceholderTF: UITextField!
    
    @IBOutlet weak var backspaceButton: UIButton!
    
    // Predictive Text Dictionary
    private var predictionEngineManager = PredictionEngineManager.shared
    fileprivate var enteredKeyList = [Int]()
    private var keyboardLabels = [UILabel]()
    private var keyboardView: UIView!
    @IBOutlet weak var keyboardContainerView: UIView!

    // SwiftUI Text Display Integration
    private var textDisplayViewModel: TextDisplayViewModel!
    private var textDisplayHostingController: UIHostingController<TextDisplayView>!

    // SwiftUI Keyboard Integration
    private var keyboardViewModel: KeyboardViewModel!
    private var keyboardHostingController: UIHostingController<KeyboardView>!
    
    private var keyLetterGrouping = [String]()
    @IBOutlet var predictionLabels: [UILabel]!
    
    // Build Word Mode
    @IBOutlet weak var buildWordButton: UIButton!
    @IBOutlet weak var buildWordConfirmButton: UIButton!
    @IBOutlet weak var buildWordCancelButton: UIButton!
    
    private var inBuildWordMode = false

    private var buildWordTimer = Timer()
    private var buildWordProgressIndex = 0
    private var buildWordLetterIndex = -1
    private var buildWordResult = ""
    private var buildWordPauseSeconds = 3.5

    // When selecting a word
    private var highlightedLabel: UILabel?

    var numPredictionLabels: Int {
        return predictionLabels.count
    }
    
    var highlightableLabels: [UILabel] {
        return predictionLabels + [wordLabel]
    }

    var usesTwoStrokesKeyboard: Bool {
        return UserPreferences.shared.keyboardLayout == .strokes2 || UserPreferences.shared.keyboardLayout == .msr
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Initialize the speech engine
        _ = SpeechSynthesizer.shared

        // Setup SwiftUI text display integration
        setupSwiftUITextDisplay()

        // Setup SwiftUI keyboard integration
        setupSwiftUIKeyboard()

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardLayoutDidChange(_:)),
                                               name: NSNotification.Name.KeyboardLayoutDidChange,
                                               object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(userAddedWordsUpdated(_:)),
                                               name: NSNotification.Name.UserAddedWordsUpdated,
                                               object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if !viewDidAppear {
            // This will be animated to value 1.0 in `viewDidAppear`
            self.view.alpha = 0.0
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !viewDidAppear {
            viewDidAppear = true
            
            buildWordPauseSeconds = UserPreferences.shared.longerPauseBetweenLetters ? 3.5 : 2.0

            setupUI()
            setupWordPredictionEngine()
            
            UIView.animate(withDuration: 0.25,
                           delay: 0,
                           options: [.curveEaseIn],
                           animations: { self.view.alpha = 1.0 },
                           completion: nil)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if inBuildWordMode {
            cancelBuildWordMode()
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { (context) in
            self.view.alpha = 0.0   
        }) { (context) in
            self.setupUI()

            UIView.animate(withDuration: 0.25,
                           delay: 0,
                           options: [.curveEaseIn],
                           animations: { self.view.alpha = 1.0 },
                           completion: { (completed) in
            })
        }
    }
    
    // MARK: - Setup

    private func setupSwiftUITextDisplay() {
        // Create the SwiftUI text display components
        textDisplayViewModel = TextDisplayViewModel()

        // Setup callbacks for SwiftUI interactions
        setupSwiftUICallbacks()

        let textDisplayView = TextDisplayView(viewModel: textDisplayViewModel)
        textDisplayHostingController = UIHostingController(rootView: textDisplayView)

        // Add as child view controller
        addChild(textDisplayHostingController)

        // Configure the hosting controller's view
        textDisplayHostingController.view.translatesAutoresizingMaskIntoConstraints = false
        textDisplayHostingController.view.backgroundColor = .clear

        // We'll add it to the table view in setupUI after the outlets are connected
    }

    private func setupSwiftUICallbacks() {
        textDisplayViewModel.onSentenceTapped = { [weak self] in
            self?.sentenceLabelTouched()
        }

        textDisplayViewModel.onSentenceLongPressed = { [weak self] in
            self?.sentenceLabelLongPressed()
        }

        textDisplayViewModel.onPredictionSelected = { [weak self] prediction, index in
            _ = self?.addWordToSentence(word: prediction, announce: true)
        }

        textDisplayViewModel.onPredictionLongPressed = { [weak self] prediction, index in
            _ = self?.addWordToSentence(word: prediction, announce: false)
        }

        textDisplayViewModel.onAnnounce = { [weak self] text in
            self?.announce(text)
        }
    }

    private func setupSwiftUIKeyboard() {
        // Create the SwiftUI keyboard components
        keyboardViewModel = KeyboardViewModel()

        // Setup callbacks for SwiftUI keyboard interactions
        setupSwiftUIKeyboardCallbacks()

        let keyboardView = KeyboardView(viewModel: keyboardViewModel)
        keyboardHostingController = UIHostingController(rootView: keyboardView)

        // Add as child view controller
        addChild(keyboardHostingController)

        // Configure the hosting controller's view
        keyboardHostingController.view.translatesAutoresizingMaskIntoConstraints = false
        keyboardHostingController.view.backgroundColor = .clear

        // We'll add it to the keyboard container in setupUI after the outlets are connected
    }

    private func setupSwiftUIKeyboardCallbacks() {
        keyboardViewModel.onWordCompleted = { [weak self] word in
            _ = self?.addWordToSentence(word: word, announce: true)
        }

        keyboardViewModel.onLetterAdded = { [weak self] letter in
            // Update the current word display
            self?.updateCurrentWordDisplay()
        }

        keyboardViewModel.onBackspace = { [weak self] in
            self?.backspace(noSound: true) // noSound because KeyboardViewModel already plays sound
        }

        keyboardViewModel.onSpace = {
            // Space is handled by word completion in SwiftUI keyboard
        }

        keyboardViewModel.onPredictionSelected = { [weak self] prediction in
            _ = self?.addWordToSentence(word: prediction, announce: true)
        }
    }

    private func updateCurrentWordDisplay() {
        print("🔍 MainTVC: updateCurrentWordDisplay called - wordLabel.text: '\(wordLabel.text ?? "")'")
        // Update the KeyboardViewModel with the current word from MainTVC
        keyboardViewModel.updateCurrentWord(wordLabel.text ?? "")

        // Update the text display view model
        textDisplayViewModel.setWordText(wordLabel.text ?? "")

        // Update predictions in text display
        let currentPredictions = predictionLabels.map { $0.text ?? "" }
        let predictionsWithFreq = currentPredictions.enumerated().map { ($0.element, 100 - $0.offset) }
        keyboardViewModel.updatePredictions(predictionsWithFreq)
        textDisplayViewModel.updatePredictions(currentPredictions)
    }

    private func setupSwiftUIKeyboardOverlay() {
        guard let hostingController = keyboardHostingController else { return }

        // Add the SwiftUI keyboard view to the keyboard container
        keyboardContainerView.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)

        // Position the SwiftUI keyboard to fill the keyboard container
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: keyboardContainerView.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: keyboardContainerView.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: keyboardContainerView.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: keyboardContainerView.bottomAnchor)
        ])

        // Ensure the SwiftUI keyboard is interactive
        hostingController.view.isUserInteractionEnabled = true

        // Update the keyboard layout to match user preferences
        keyboardViewModel.keyboardLayout = UserPreferences.shared.keyboardLayout

        // Setup binding to sync KeyboardViewModel with legacy enteredKeyList
        setupKeyboardViewModelBinding()
    }

    private func setupKeyboardViewModelBinding() {
        // Observe changes to KeyboardViewModel's enteredKeys and sync with legacy enteredKeyList
        keyboardViewModel.$enteredKeys
            .receive(on: DispatchQueue.main)
            .sink { [weak self] keys in
                print("🔍 MainTVC: Received enteredKeys update: \(keys)")
                self?.enteredKeyList = keys
                self?.updatePredictions()
                self?.updateCurrentWordDisplay()
            }
            .store(in: &cancellables)
    }

    private var cancellables = Set<AnyCancellable>()

    private func setupSwiftUITextDisplayOverlay() {
        guard let hostingController = textDisplayHostingController else { return }

        // Hide the original UIKit labels and text fields
        sentenceLabel.isHidden = true
        wordLabel.isHidden = true
        sentencePlaceholderTF.isHidden = true
        wordPlaceholderTF.isHidden = true
        for label in predictionLabels {
            label.isHidden = true
        }

        // Add the SwiftUI view as an overlay
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)

        // Position the SwiftUI view to cover the text display area (first 3 table sections)
        // Calculate the height of the first 3 sections (sentence, word, predictions)
        let textDisplayHeight: CGFloat = 44 + 44 + 88 // Approximate heights of the 3 sections

        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: tableView.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.heightAnchor.constraint(equalToConstant: textDisplayHeight)
        ])

        // Ensure the SwiftUI view doesn't interfere with table view scrolling
        hostingController.view.isUserInteractionEnabled = true

        // Initialize with current text values
        textDisplayViewModel.setSentenceText(sentenceLabel.text ?? "")
        textDisplayViewModel.setWordText(wordLabel.text ?? "")

        // Update predictions if they exist
        let currentPredictions = predictionLabels.map { $0.text ?? "" }
        textDisplayViewModel.updatePredictions(currentPredictions)
    }

    private func setupWordPredictionEngine() {
        // Set key letter grouping for current engine
        predictionEngineManager.currentEngine?.setKeyLetterGrouping(keyLetterGrouping, twoStrokes: usesTwoStrokesKeyboard)

        // Only load words into custom engine (native engine uses system dictionary)
        guard let customEngine = predictionEngineManager.engines[.custom] as? WordPredictionEngine else {
            return
        }

        Task {
            // Capture values on main actor
            let userWordRating = await MainActor.run { UserPreferences.shared.userWordRating }
            let userAddedWords = await MainActor.run { UserPreferences.shared.userAddedWords }
            let wordAndFrequencyList = MainTVC.wordAndFrequencyList

            // Process on background queue
            await Task.detached(priority: .userInitiated) {
                // Add user added words
                for userAddedWord in userAddedWords {
                    let wordRating = userWordRating[userAddedWord] ?? 0
                    do {
                        try customEngine.insert(userAddedWord, Constants.defaultWordFrequency + wordRating)
                    } catch WordPredictionError.unsupportedWord(let invalidChar) {
                        print("Cannot add word '\(userAddedWord)', invalid char '\(invalidChar)'")
                    } catch {
                        print("Cannot add word '\(userAddedWord)', error: \(error)")
                    }
                }

                // Add dictionary words
                for (word, frequency) in wordAndFrequencyList {
                    let wordRating = userWordRating[word]
                    let frequencyToUse = (wordRating != nil) ? Constants.defaultWordFrequency + wordRating! : frequency

                    do {
                        try customEngine.insert(word, frequencyToUse)
                    } catch WordPredictionError.unsupportedWord(_) {
                        //print("Cannot add word '\(word)', invalid char '\(invalidChar)'")
                    } catch {
                        print("Cannot add word '\(word)', error: \(error)")
                    }
                }
            }.value
        }
    }
    
    private func setupUI() {
        tableView.isScrollEnabled = false

        // Setup SwiftUI keyboard overlay (replaces UIKit keyboard setup)
        setupSwiftUIKeyboardOverlay()

        // Setup SwiftUI text display overlay
        setupSwiftUITextDisplayOverlay()

        setSentenceText("")
        
        for label in highlightableLabels {
            label.isUserInteractionEnabled = true
            label.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleLabelTapAction(_:))))
            label.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(handleLabelLongPressAction(_:))))

            // Enhanced accessibility
            label.isAccessibilityElement = true
            label.accessibilityTraits = .button
        }
        
        if let buildTitleLabel = buildWordButton.titleLabel {
            buildTitleLabel.adjustsFontSizeToFitWidth = true
            buildTitleLabel.minimumScaleFactor = 0.75
        }
        
        backspaceAll()
        resetBuildWordMode()
        dehighlightLabel()
    }
    
    private func setupKeyboard() {
        // DISABLED: UIKit keyboard setup is now replaced by SwiftUI keyboard
        // The SwiftUI keyboard is managed by setupSwiftUIKeyboardOverlay()

        // Clean up any existing UIKit keyboard views
        if keyboardView != nil && keyboardView.superview != nil {
            keyboardView.removeFromSuperview()
            keyboardLabels.removeAll()
        }

        // Set up keyLetterGrouping for legacy compatibility (still needed for build word mode)
        switch UserPreferences.shared.keyboardLayout {
        case .keys4:
            keyLetterGrouping = Constants.keyLetterGrouping4Keys
        case .keys6:
            keyLetterGrouping = Constants.keyLetterGrouping6Keys
        case .keys8:
            keyLetterGrouping = Constants.keyLetterGrouping8Keys
        case .strokes2:
            keyLetterGrouping = Constants.keyLetterGroupingSteve
        case .msr:
            keyLetterGrouping = Constants.keyLetterGroupingMSR
        }

        // Ensure container has clear background for SwiftUI keyboard
        keyboardContainerView.backgroundColor = UIColor.clear
    }
    
    private static func keyboardSize(_ keyboardContainerView: UIView) -> CGSize {
        let containerWidth = keyboardContainerView.frame.width
        let containerHeight = keyboardContainerView.frame.height
        
        var width = min(keyboardContainerView.frame.width, keyboardContainerView.frame.height)
        var height = min(keyboardContainerView.frame.width, keyboardContainerView.frame.height)
        
        if UserPreferences.shared.keyboardLayout == .keys6 ||
            UserPreferences.shared.keyboardLayout == .strokes2 ||
            UserPreferences.shared.keyboardLayout == .msr {
            
            if UIDevice.current.userInterfaceIdiom == .phone {
                // iPhone 8 Plus
                if containerHeight > 390 {
                    height *= 0.7
                }
                // iPhone 8
                else if containerHeight > 322 {
                    height *= 0.7
                    width *= 1.1
                }
                // iPhone 5
                else {
                    height *= 0.9
                    width *= 1.4
                }
            } else if UIDevice.current.userInterfaceIdiom == .pad {
                let landscape = containerWidth/containerHeight > 2.0
                
                if landscape {
                    height *= 0.9
                    width *= 1.3
                } else {
                    height *= 0.75
                    width *= 1.05
                }
            }
        }
        
        // Just in case, make sure the size is within bounds
        width = min(width, containerWidth)
        height = min(height, containerHeight)

        return CGSize(width: width, height: height)
    }
    
    private func adjustKeysFont() {
        guard !changedLabelFonts else { return }
        
        let iPhone5ScreenHeight: CGFloat = 568
        let multiplier: CGFloat
        
        // Make fonts bigger for bigger devices (iPads)
        if traitCollection.horizontalSizeClass == .regular &&
            traitCollection.verticalSizeClass == .regular {
            multiplier = 1.5
        }
        // Make fonts smaller for small devices (iPhone 5 and below)
        else if UIScreen.main.bounds.size.height <= iPhone5ScreenHeight {
            multiplier = 0.9
        } else {
            return
        }
        
        let keyboardViews = [keysView4Keys, keysView6Keys, keysView8Keys, keysView2Strokes, keyboardMSMaster]
        
        for keyboardView in keyboardViews {
            guard let keyboardView = keyboardView else { continue }
            for subview in keyboardView.subviews {
                guard let label = subview as? UILabel else { continue }

                label.font = label.font.withSize(label.font.pointSize * multiplier)
            }
        }
        
        changedLabelFonts = true
    }
    
    // MARK: - Notifications

    @objc private func keyboardLayoutDidChange(_ notification: Notification) {
        // Update keyboard layout grouping for legacy compatibility
        setupKeyboard()

        // Update SwiftUI keyboard layout
        keyboardViewModel.keyboardLayout = UserPreferences.shared.keyboardLayout

        setupWordPredictionEngine()
    }
    
    @objc private func userAddedWordsUpdated(_ notification: Notification) {
        //setupUI()
        //setupWordPredictionEngine()
        
        guard let userInfo = notification.userInfo else { return }
        guard let word = userInfo[WordKeys.word] as? String, let freq = userInfo[WordKeys.frequency] as? Int else { return }

        try? predictionEngineManager.currentEngine?.insert(word, freq)
    }
    
    // MARK: User UI Interaction

    @IBAction func presentSettings() {
        let settingsViewController = SwiftUIBridge.createSettingsViewController()
        present(settingsViewController, animated: true)
    }

    @IBAction func backspace() {
        backspace(noSound: false)
    }
    
    private func backspace(noSound: Bool = false) {
        defer {
            if UserPreferences.shared.keyboardLayout == .msr {
                changeKeyboardKeysToMaster()
            }
        }
        
        if inBuildWordMode { return }
        //if !buildWordConfirmButton.isHidden { return }
        
        dehighlightLabel()
        
        updateKeyboardIndicator(-1)
        if enteredKeyList.count == 0 && !wordLabelContainsArrowSuffix() {
            return
        }
        
        // Remove first stroke or last character.
        if keyboardViewModel.firstStroke != nil {
            keyboardViewModel.firstStroke = nil
        } else { // Remove last character.
            enteredKeyList.removeLast()
            updatePredictions()
        }
        
        if !noSound && UserPreferences.shared.audioFeedback {
            playSoundBackspace()
        }
        
        if usesTwoStrokesKeyboard {
            removeArrowSuffix()
        } else {
            showCurrentArrows()
        }
    }
    
    @IBAction func backspaceAll() {
        if inBuildWordMode { return }
        // if !buildWordConfirmButton.isHidden { return }
        
        if !enteredKeyList.isEmpty {
            if UserPreferences.shared.audioFeedback {
                playSoundBackspace()
            }
        }
        
        enteredKeyList.removeAll()
        updatePredictions()
        updateKeyboardIndicator(-1)
        keyboardViewModel.firstStroke = nil
    }
    
    @IBAction func handleLabelTapAction(_ sender: UITapGestureRecognizer) {
        guard let label = sender.view as? UILabel else { return }
        handleLabelTapAction(from: label)
    }
    
    private func handleLabelTapAction(from label: UILabel, forcePromote: Bool = false) {
        guard let text = label.text, !text.isEmpty else { return }
        guard !text.containsArrow() else { return }
        
        guard forcePromote || highlightableLabels.contains(label) else {
            return
        }
        
        if forcePromote || (highlightedLabel != nil && highlightedLabel == label) {
            _ = addWordToSentence(from: label, announce: true)
        } else {
            highlight(label: label)
            announce(text)
        }
    }
    
    @IBAction func handleLabelLongPressAction(_ sender: UILongPressGestureRecognizer) {
        guard sender.state == .began else { return }
        guard let label = sender.view as? UILabel else { return }
        
        _ = addWordToSentence(from: label)
    }

    @IBAction func sentenceLabelTouched() {
        guard let text = sentenceLabel.text, !text.isEmpty else { return }
        
        announce(text)
        sentenceLabelLongPressed()
    }
    
    @IBAction func sentenceLabelLongPressed() {
        completeSentence()
    }
    
    // MARK: UI Actions

    private func updateKeyboardIndicator(_ index: Int) {
        resetKeysBoarder()
        
        if index != -1 {
            // Visual indicator
            keyboardLabels[index].layer.borderWidth = 3
        }
    }
    
    private func removeArrowSuffix() {
        guard wordLabelContainsArrowSuffix(), let wordLabelText = wordLabel.text else {
            return
        }
        
        setWordText(String(wordLabelText.dropLast()))
    }
    
    // Input box should has same length as entered keys.
    // E.g. if key list is [down, right, left], "unit" is the first prediction.
    // But there are only 3 keys in list, so we should show "uni" in input box.
    private func trimmedStringForwordLabel(_ result: String) -> String {
        guard !result.isEmpty else {
            return ""
        }
        
        let toIndex = result.index(result.startIndex, offsetBy: enteredKeyList.count)
        return String(result[..<toIndex])
    }
    
    private func announceDirection(for key: Int, with keyboardLayout: KeyboardLayout) {
        guard UserPreferences.shared.announceLettersCount else {
            return
        }
        
        let arrows: [Int: String]

        switch keyboardLayout {
        case .keys4:
            arrows = Constants.arrows4KeysTextMap
        case .strokes2, .msr:
            arrows = Constants.arrows2StrokesTextMap
        default:
            return
        }
        
        guard let arrowText = arrows[key] else { return }
        announce(NSLocalizedString(arrowText, comment: ""))
    }
    
    func announce(_ text: String) {
        SpeechSynthesizer.shared.speak(text)
    }
    
    private func resetAfterWordAdded() {
        dehighlightLabel()
        enteredKeyList = [Int]()
        setWordText("")
        
        for label in predictionLabels {
            label.text = ""
        }
        
        buildWordButton.setTitle("", for: .normal)

        updateKeyboardIndicator(-1)
    }
    
    private func addWordToSentence(from label: UILabel, announce: Bool = false) -> Bool {
        guard let word = label.text else { return false }
        
        return addWordToSentence(word: word, announce: announce)
    }
    
    func addWordToSentence(word: String, announce: Bool = false) -> Bool {
        guard !word.isEmpty, !word.containsArrow() else {
            return false
        }
        
        dehighlightLabel()
        
        // Audio feedback after adding a word.
        if UserPreferences.shared.audioFeedback {
            if announce {
                self.announce(word)
            } else {
                playSoundWordAdded()
            }
        }
        
        let currentSentence = sentenceLabel.text ?? ""
        setSentenceText(currentSentence + word + " ")
        
        resetAfterWordAdded()
        resetBuildWordMode()
        
        if let currentEngine = predictionEngineManager.currentEngine, !currentEngine.contains(word) {
            UserPreferences.shared.addWord(word)
            try? currentEngine.insert(word, Constants.defaultWordFrequency)
        }
        
        UserPreferences.shared.incrementWordRating(word)
        setupWordPredictionEngine()

        keyboardViewModel.firstStroke = nil
        
        return true
    }
    
    private func completeSentence() {
        guard let text = sentenceLabel.text, !text.isEmpty else { return }
        
        UserPreferences.shared.addSentence(text)
        
        resetAfterWordAdded()
        setSentenceText("")
    }
    
    // Update input box and predictions
    private func updatePredictions() {
        // Initialize.
        for label in predictionLabels {
            label.text = ""
        }
        
        buildWordButton.setTitle("", for: .normal)

        guard !enteredKeyList.isEmpty else {
            setWordText("")
            return
        }
        
        // Possible words from input letters.
        if !usesTwoStrokesKeyboard {
            buildWordButton.setTitle(MainTVC.buildWordButtonText, for: .normal)
        }
        
        // Possible words from input T9 digits.
        let results = predictionEngineManager.currentEngine?.suggestions(for: enteredKeyList) ?? []
        
        var prediction = [(String, Int)]()

        // Show first result in input box.
        if results.count >= numPredictionLabels {
            // If we already get enough results, we do not need add characters to search predictions.
            setWordText(results[0].0)
            // Results is already sorted.
            for i in 0 ..< numPredictionLabels {
                prediction.append(results[i])
            }
        } else {
            // Add characters after input to get more predictions.
            var digits = [enteredKeyList]
            var searchLevel = 0
            var maxSearchLevel = 4
            
            if usesTwoStrokesKeyboard {
                maxSearchLevel = 2
            }
            
            // Do not search too many mutations.
            while (prediction.count < numPredictionLabels - results.count && searchLevel < maxSearchLevel) {
                var newDigits = [[Int]]()
                for digit in digits {
                    if usesTwoStrokesKeyboard {
                        for letterValue in UnicodeScalar("a").value...UnicodeScalar("z").value {
                            newDigits.append(digit+[Int(letterValue)])
                        }
                    } else {
                        for i in 0 ..< UserPreferences.shared.keyboardLayout.rawValue {
                            newDigits.append(digit+[i])
                        }
                    }
                }
                for digit in newDigits {
                    prediction += predictionEngineManager.currentEngine?.suggestions(for: digit) ?? []
                }
                digits = newDigits
                
                searchLevel += 1
            }
            
            // Sort all predictions based on frequency.
            prediction.sort { $0.1 > $1.1 }
            
            for i in 0 ..< results.count {
                prediction.insert(results[i], at: i)
            }
            
            if usesTwoStrokesKeyboard {
                var inputString = ""
                for letterValue in enteredKeyList {
                    inputString += MainTVC.letter(from: letterValue)!
                }
                
                if (prediction.count == 0 || prediction[0].0 != inputString) {
                    prediction.insert((inputString, 0), at: 0)
                }
            }
            
            // Cannot find any prediction.
            if (prediction.count == 0) {
                let currentText = self.wordLabel.text ?? ""
                setWordText(trimmedStringForwordLabel(currentText + "?"))
                return
            }
            
            let firstPrediction = prediction[0].0
            if firstPrediction.count >= enteredKeyList.count {
                setWordText(trimmedStringForwordLabel(firstPrediction))
            } else {
                let currentText = self.wordLabel.text ?? ""
                setWordText(trimmedStringForwordLabel(currentText + "?"))
            }
        }
        
        // Show predictions in prediction boxs.
        for i in 0 ..< min(numPredictionLabels - 1, prediction.count) {
            predictionLabels[i].text = prediction[i].0
        }

        // Update SwiftUI component
        let currentPredictions = predictionLabels.map { $0.text ?? "" }
        textDisplayViewModel?.updatePredictions(currentPredictions)
    }
    
    private func highlight(label: UILabel) {
        dehighlightLabel()
        highlightedLabel = label
        label.font = UIFont.boldSystemFont(ofSize: label.font.pointSize + 4)
    }
    
    private func dehighlightLabel() {
        guard highlightedLabel != nil else { return }
        
        highlightedLabel!.font = UIFont.preferredFont(forTextStyle: .body)
        highlightedLabel = nil
    }
    
    private func setSentenceText(_ text: String) {
        sentencePlaceholderTF.placeholder = text.isEmpty ? NSLocalizedString("Sentence", comment: "") : ""
        sentenceLabel.text = text

        // Update accessibility
        sentenceLabel.accessibilityLabel = text.isEmpty ?
            NSLocalizedString("Sentence area. Tap letters to spell words", comment: "") :
            NSLocalizedString("Current sentence: \(text)", comment: "")

        // Update SwiftUI component
        textDisplayViewModel?.setSentenceText(text)
    }
    
    private func setWordText(_ text: String) {
        wordPlaceholderTF.placeholder = text.isEmpty ? NSLocalizedString("Word", comment: "") : ""
        wordLabel.text = text

        // Update accessibility
        wordLabel.accessibilityLabel = text.isEmpty ?
            NSLocalizedString("Word area. Current input is empty", comment: "") :
            NSLocalizedString("Current word input: \(text)", comment: "")

        // Update SwiftUI component
        textDisplayViewModel?.setWordText(text)
    }
    
    private func resetKeysBoarder() {
        for key in keyboardLabels {
            key.layer.borderWidth = 0
        }
    }
    
    private func showCurrentArrows() {
        let arrows = MainTVC.directionArrows(for: enteredKeyList)
        setWordText(arrows)
    }
    
    // MARK: - Scanning Mode
    
    @IBAction func buildWordButtonTouched() {
        guard !usesTwoStrokesKeyboard else {
            return
        }
        
        guard enteredKeyList.count > 0 else {
            return
        }
        
        inBuildWordMode = true
        tableView.reloadData()
        
        buildWordProgressIndex = 0
        buildWordTimer = Timer.scheduledTimer(timeInterval: buildWordPauseSeconds,
                                              target: self,
                                              selector: #selector(self.scanningLettersOnKey),
                                              userInfo: nil,
                                              repeats: true)

        self.setWordText(MainTVC.buildWordButtonText)
        self.announce(self.wordLabel.text!)
    }
    
    @objc func scanningLettersOnKey() {
        guard enteredKeyList.indices.contains(buildWordProgressIndex) else { return }
        let enteredKey = enteredKeyList[buildWordProgressIndex]
        
        guard keyLetterGrouping.indices.contains(enteredKey) else { return }
        let lettersOnKey = keyLetterGrouping[enteredKey]
      
        buildWordLetterIndex += 1
        buildWordLetterIndex %= lettersOnKey.count
       
        guard buildWordLetterIndex < lettersOnKey.count else { return }
        let letter = lettersOnKey[buildWordLetterIndex]
     
        self.announce(String(letter))
        self.setWordText(self.buildWordResult + String(letter))
        
        self.resetKeysBoarder()
        
        guard keyboardLabels.indices.contains(enteredKey) else { return }
        self.keyboardLabels[enteredKey].layer.borderWidth = 3
    }
    
    private func resetBuildWordMode() {
        buildWordTimer.invalidate()
        buildWordProgressIndex = 0
        buildWordLetterIndex = -1
        enteredKeyList = [Int]()
        buildWordResult = ""
        resetKeysBoarder()
    }
    
    @IBAction func buildWordConfirmButtonTouched() {
        guard buildWordLetterIndex != -1 else { return }
        
        let letter = keyLetterGrouping[enteredKeyList[buildWordProgressIndex]][buildWordLetterIndex]
        buildWordResult.append(letter)
        
        // Complete the whole word
        guard buildWordResult.count < enteredKeyList.count else {
            let buildWordResult = String(self.buildWordResult)
            UserPreferences.shared.addWord(self.buildWordResult)
         
            setWordText(buildWordResult)
            
            var word = ""
            for letter in buildWordResult {
                word += (String(letter) + ", ")
            }
            announce(word + buildWordResult)
            
            setSentenceText(sentenceLabel.text! + buildWordResult + " ")
            
            cancelBuildWordMode()
            return
        }
        
        buildWordProgressIndex += 1
        buildWordLetterIndex = -1
        
        setWordText(buildWordResult)
        
        buildWordTimer.invalidate()
        
        var word = ""
        for letter in buildWordResult {
            word += (String(letter) + ", ")
        }
        announce(word + " " + NSLocalizedString("Next Letter", comment: ""))
        
        sleep(UInt32(buildWordResult.count / 2))
        buildWordTimer = Timer.scheduledTimer(timeInterval: self.buildWordPauseSeconds,
                                              target: self,
                                              selector: #selector(self.scanningLettersOnKey),
                                              userInfo: nil,
                                              repeats: true)
    }
    
    @IBAction func cancelBuildWordMode() {
        resetBuildWordMode()
        
        inBuildWordMode = false
        tableView.reloadData()
        
        self.setWordText("")
        
        for label in self.predictionLabels {
            label.text = ""
        }
        
        buildWordButton.setTitle("", for: .normal)
    }
    
    func changeKeyboardKeysToMaster() {
        let keys = wordOrSentenceHasText() ? Constants.MSRKeyboardMasterKeys2 : Constants.MSRKeyboardMasterKeys1
        changeKeyboardKeys(keys)
    }
    
    func changeKeyboardKeysToDetail(for key: SwipeViewKeyNum) {
        let keys = wordOrSentenceHasText() ? Constants.MSRKeyboardDetailKeys2[key] : Constants.MSRKeyboardDetailKeys1[key]
        changeKeyboardKeys(keys)
    }
    
    func changeKeyboardKeys(_ keys: [String]) {
        currentKeys = keys
        
        for (index, label) in keyboardLabels.enumerated() {
            let key = keys[index]
            
            UIView.transition(with: label,
                              duration: 0.2,
                              options: .transitionCrossDissolve,
                              animations: {
                                label.text = key
                                if key == "yes" || key == "no" || key == "oops" {
                                    label.textColor = .red
                                } else {
                                    label.textColor = .white
                                }
            }, completion: nil)
        }
    }
    
    // MARK: - Helper Methods

    private func wordLabelContainsArrowSuffix() -> Bool {
        guard let char = wordLabel.text?.last else { return false }
        return String(char).containsArrow()
    }
    
    private static func letter(from key: Int) -> String? {
        guard let scalar = UnicodeScalar(key) else { return nil }
        return String(describing: scalar)
    }
    
    private static func directionArrows(for keys: [Int]) -> String {
        guard !keys.isEmpty else { return "" }
        let arrows = keys.compactMap { Constants.arrows4KeysMap[$0] }
        return arrows.joined(separator: "")
    }
    
    func wordOrSentenceHasText() -> Bool {
        if let word = wordLabel.text, word.count > 0 {
            return true
        }
        if let sentence = sentenceLabel.text, sentence.count > 0 {
            return true
        }
        return false
    }
    
    // MARK: - Table View

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 2: // Prediction labels
            return inBuildWordMode ? 0 : 44
        case 3: // Build word buttons
            return inBuildWordMode ? 44 : 0
        case 4: // Keyboard view
            return view.bounds.height - 255 - 25
        default:
            return 44
        }
    }
    
}

// MARK: - SwipeViewDelegate

extension MainTVC: @preconcurrency SwipeViewDelegate {

    // MARK: Methods

    func keyEntered(key: SwipeViewKeyNum, isSwipe: Bool) {
        keyEntered(isSwipe: isSwipe)
        
        enteredKeyList.append(key)
        
        // Update predictive text for key list.
        updatePredictions()
        updateKeyboardIndicator(key)
        
        announceDirection(for: key, with: .keys4)
    
        showCurrentArrows()
    }
    
    func firstStrokeEntered(key: SwipeViewKeyNum, isSwipe: Bool) {
        print("STROKE 1 [key=\(key)]")

        keyEntered(isSwipe: isSwipe)

        updateKeyboardIndicator(key)
        
        if UserPreferences.shared.keyboardLayout == .msr {
            changeKeyboardKeysToDetail(for: key)
        }
        
        guard let arrow = Constants.arrows2StrokesMap[key] else { return }
        let text = (wordLabel.text ?? "") + arrow
        setWordText(text)
        
        announceDirection(for: key, with: .strokes2)
    }
    
    func secondStrokeEntered(key: SwipeViewKeyNum, isSwipe: Bool) {
        print("STROKE 2 [key=\(key)]")

        defer {
            if UserPreferences.shared.keyboardLayout == .msr {
                changeKeyboardKeysToMaster()
            }
        }
        
        var key = key

        if UserPreferences.shared.keyboardLayout == .msr {
            
            let keyString = currentKeys[key]
            
            guard keyString != Constants.MSRKeyDelete else {
                handleKeyDelete()
                return
            }
            
            keyEntered(isSwipe: isSwipe)
            
            guard keyString != Constants.MSRKeyYes else {
                handleKeyYes()
                return
            }
            
            guard keyString != Constants.MSRKeyNo else {
                handleKeyNo()
                return
            }
            
            guard keyString != Constants.MSRKeyCancel else {
                handleKeyCancel()
                return
            }
            
            guard keyString != Constants.MSRKeySpeak else {
                handleKeyPromote()
                return
            }
            
            guard let keyScalar = UnicodeScalar(keyString.lowercased()) else { return }
            let keyInt = Int(keyScalar.value)
            
            key = keyInt
        }
        
        enteredKeyList.append(key)
        updateKeyboardIndicator(-1)
        updatePredictions()
        
        guard let letter = MainTVC.letter(from: key) else { return }
        announce(letter)
    }
    
    private func keyEntered(isSwipe: Bool) {
        if UserPreferences.shared.audioFeedback {
            if isSwipe {
                playSoundSwipe()
            } else {
                playSoundClick()
            }
        }
        
        if UserPreferences.shared.vibrate {
            vibrate()
        }
    }
    
    func longPressBegan() {
        // Try to select word
        if !addWordToSentence(from: wordLabel, announce: true) {
            // Try to complete phrase
            sentenceLabelTouched()
        }
    }
    
}

// MARK: Special Keys

extension MainTVC {
    
    func handleKeyYes() {
        backspace(noSound: true)
        announce("Yes")
    }
    
    func handleKeyNo() {
        backspace(noSound: true)
        announce("No")
    }
    
    func handleKeyCancel() {
        backspace(noSound: true)
    }
    
    func handleKeyPromote() {
        removeArrowSuffix()
        
        // Check if word should be promoted to sentence
        if let word = wordLabel.text, word.count > 0, !word.containsArrow() {
            handleLabelTapAction(from: wordLabel, forcePromote: true)
            return
        }
        
        // Check if sentence should be outputted
        if let sentence = sentenceLabel.text, sentence.count > 0 {
            sentenceLabelTouched()
        }
    }
    
    func handleKeyDelete() {
        backspace(noSound: true)
        backspace(noSound: false)
    }
    
}

extension CharacterSet {
    static let arrowCharacters = CharacterSet(charactersIn: "↑↗︎→↘︎↓↙︎←↖︎")
}

extension String {
    func containsArrow() -> Bool {
        return self.rangeOfCharacter(from: CharacterSet.arrowCharacters) != nil
    }
}
