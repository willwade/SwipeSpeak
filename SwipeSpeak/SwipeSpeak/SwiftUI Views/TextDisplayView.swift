//
//  TextDisplayView.swift
//  SwipeSpeak
//
//  Created by SwiftUI Migration on 2025-01-20.
//  Copyright © 2025 TeamGleason. All rights reserved.
//

import SwiftUI

/// SwiftUI component for displaying sentence and word text with enhanced accessibility
struct TextDisplayView: View {
    @ObservedObject var viewModel: TextDisplayViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Sentence Display Section
            VStack(spacing: 0) {
                SentenceDisplayView(
                    text: viewModel.sentenceText,
                    placeholder: LocalizedStrings.Placeholder.sentence,
                    onTap: viewModel.sentenceTapped,
                    onLongPress: viewModel.sentenceLongPressed
                )
                .padding(.horizontal, 20)
                .padding(.vertical, 11)
                .background(Color(.systemBackground))

                // Section separator
                Rectangle()
                    .fill(Color(.separator))
                    .frame(height: 0.5)
            }

            // Word Display Section
            VStack(spacing: 0) {
                WordDisplayView(
                    text: viewModel.wordText,
                    placeholder: LocalizedStrings.Placeholder.word,
                    isHighlighted: viewModel.isWordHighlighted,
                    onTap: viewModel.wordTapped,
                    onLongPress: viewModel.wordLongPressed
                )
                .padding(.horizontal, 20)
                .padding(.vertical, 11)
                .background(Color(.systemBackground))

                // Section separator
                Rectangle()
                    .fill(Color(.separator))
                    .frame(height: 0.5)
            }

            // Prediction Labels Section - expand to fill remaining space
            PredictionLabelsView(
                predictions: viewModel.predictions,
                highlightedIndex: viewModel.highlightedPredictionIndex,
                onPredictionTap: viewModel.predictionTapped,
                onPredictionLongPress: viewModel.predictionLongPressed
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

/// Individual sentence display component
struct SentenceDisplayView: View {
    let text: String
    let placeholder: String
    let onTap: () -> Void
    let onLongPress: () -> Void
    
    var body: some View {
        HStack {
            if text.isEmpty {
                Text(placeholder)
                    .foregroundColor(.secondary)
                    .font(.body)
            } else {
                Text(text)
                    .font(.body)
                    .foregroundColor(.primary)
            }
            Spacer()
        }
        .frame(minHeight: 44)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .onLongPressGesture {
            onLongPress()
        }
        .accessibilityLabel(text.isEmpty ?
            LocalizedStrings.Accessibility.Sentence.empty :
            LocalizedStrings.Accessibility.Sentence.label(text))
        .accessibilityHint(LocalizedStrings.Accessibility.Sentence.hint)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(.default) {
            onTap()
        }
        .accessibilityAction(named: "Complete sentence") {
            onLongPress()
        }
    }
}

/// Individual word display component
struct WordDisplayView: View {
    let text: String
    let placeholder: String
    let isHighlighted: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void
    
    var body: some View {
        HStack {
            if text.isEmpty {
                Text(placeholder)
                    .foregroundColor(.secondary)
                    .font(.body)
            } else {
                Text(text)
                    .font(isHighlighted ? .headline : .body)
                    .fontWeight(isHighlighted ? .bold : .regular)
                    .foregroundColor(.primary)
            }
            Spacer()

            // Backspace button area (placeholder for spacing)
            Rectangle()
                .fill(Color.clear)
                .frame(width: 44, height: 44)
        }
        .frame(minHeight: 44)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .onLongPressGesture {
            onLongPress()
        }
        .accessibilityLabel(text.isEmpty ?
            LocalizedStrings.Accessibility.Word.empty :
            LocalizedStrings.Accessibility.Word.label(text))
        .accessibilityHint(LocalizedStrings.Accessibility.Word.hint)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(.default) {
            onTap()
        }
        .accessibilityAction(named: "Add to sentence") {
            onLongPress()
        }
        .animation(.easeInOut(duration: 0.2), value: isHighlighted)
    }
}

/// Prediction labels component matching original table view style
struct PredictionLabelsView: View {
    let predictions: [String]
    let highlightedIndex: Int?
    let onPredictionTap: (Int) -> Void
    let onPredictionLongPress: (Int) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // First row of predictions (0-3)
            HStack(spacing: 0) {
                ForEach(0..<4, id: \.self) { index in
                    if index > 0 {
                        // Vertical separator
                        Rectangle()
                            .fill(Color(.separator))
                            .frame(width: 0.5)
                    }

                    PredictionLabelView(
                        text: index < predictions.count ? predictions[index] : "",
                        isHighlighted: highlightedIndex == index,
                        onTap: { onPredictionTap(index) },
                        onLongPress: { onPredictionLongPress(index) }
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(height: 44)

            // Horizontal separator
            Rectangle()
                .fill(Color(.separator))
                .frame(height: 0.5)

            // Second row of predictions (4-5) + Build Word button
            HStack(spacing: 0) {
                ForEach(4..<6, id: \.self) { index in
                    if index > 4 {
                        // Vertical separator
                        Rectangle()
                            .fill(Color(.separator))
                            .frame(width: 0.5)
                    }

                    PredictionLabelView(
                        text: index < predictions.count ? predictions[index] : "",
                        isHighlighted: highlightedIndex == index,
                        onTap: { onPredictionTap(index) },
                        onLongPress: { onPredictionLongPress(index) }
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                // Vertical separator before Build Word button
                Rectangle()
                    .fill(Color(.separator))
                    .frame(width: 0.5)

                // Build Word button placeholder
                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .overlay(
                        Text("Build Word")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    )
            }
            .frame(height: 44)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Individual prediction label component
struct PredictionLabelView: View {
    let text: String
    let isHighlighted: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void

    var body: some View {
        HStack {
            Text(text)
                .font(.body)
                .fontWeight(isHighlighted ? .bold : .regular)
                .foregroundColor(text.isEmpty ? .clear : .primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Spacer()
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(isHighlighted ? Color.blue.opacity(0.1) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture {
            if !text.isEmpty {
                onTap()
            }
        }
        .onLongPressGesture {
            if !text.isEmpty {
                onLongPress()
            }
        }
        .accessibilityLabel(text.isEmpty ? "" : "Word prediction: \(text)")
        .accessibilityHint(text.isEmpty ? "" : "Double tap to select prediction, long press to add directly to sentence")
        .accessibilityAddTraits(text.isEmpty ? [] : .isButton)
        .accessibilityAction(.default) {
            if !text.isEmpty {
                onTap()
            }
        }
        .accessibilityAction(named: "Add to sentence") {
            if !text.isEmpty {
                onLongPress()
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isHighlighted)
    }
}

#if DEBUG
struct TextDisplayView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = TextDisplayViewModel()
        viewModel.sentenceText = "Hello world"
        viewModel.wordText = "test"
        viewModel.predictions = ["testing", "test", "tests", "tested", "tester", ""]
        viewModel.isWordHighlighted = true
        viewModel.highlightedPredictionIndex = 0
        
        return TextDisplayView(viewModel: viewModel)
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
#endif
