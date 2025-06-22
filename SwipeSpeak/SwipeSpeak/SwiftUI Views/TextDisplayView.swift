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
        VStack(spacing: 16) {
            // Sentence Display
            SentenceDisplayView(
                text: viewModel.sentenceText,
                placeholder: "Sentence",
                onTap: viewModel.sentenceTapped,
                onLongPress: viewModel.sentenceLongPressed
            )

            // Word Display
            WordDisplayView(
                text: viewModel.wordText,
                placeholder: "Word",
                isHighlighted: viewModel.isWordHighlighted,
                onTap: viewModel.wordTapped,
                onLongPress: viewModel.wordLongPressed
            )

            // Prediction Labels - expand to fill remaining space
            PredictionLabelsView(
                predictions: viewModel.predictions,
                highlightedIndex: viewModel.highlightedPredictionIndex,
                onPredictionTap: viewModel.predictionTapped,
                onPredictionLongPress: viewModel.predictionLongPressed
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

/// Individual sentence display component
struct SentenceDisplayView: View {
    let text: String
    let placeholder: String
    let onTap: () -> Void
    let onLongPress: () -> Void
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.secondarySystemBackground))
                .stroke(Color(.separator), lineWidth: 1)
            
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
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
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
            "Sentence area. Currently empty. Tap letters to spell words" :
            "Current sentence: \(text)")
        .accessibilityHint("Double tap to speak sentence, long press to complete and clear")
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
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.secondarySystemBackground))
                .stroke(isHighlighted ? Color.blue : Color(.separator), lineWidth: isHighlighted ? 2 : 1)
            
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
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
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
            "Word area. Current input is empty" :
            "Current word being typed: \(text)")
        .accessibilityHint("Double tap to select word, long press to add to sentence")
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

/// Prediction labels grid component
struct PredictionLabelsView: View {
    let predictions: [String]
    let highlightedIndex: Int?
    let onPredictionTap: (Int) -> Void
    let onPredictionLongPress: (Int) -> Void
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(0..<6, id: \.self) { index in
                PredictionLabelView(
                    text: index < predictions.count ? predictions[index] : "",
                    isHighlighted: highlightedIndex == index,
                    onTap: { onPredictionTap(index) },
                    onLongPress: { onPredictionLongPress(index) }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
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
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(text.isEmpty ? Color.clear : Color(.tertiarySystemBackground))
                .stroke(isHighlighted ? Color.blue : Color(.separator),
                       lineWidth: isHighlighted ? 2 : (text.isEmpty ? 0 : 1))
            
            Text(text)
                .font(isHighlighted ? .headline : .subheadline)
                .fontWeight(isHighlighted ? .bold : .regular)
                .foregroundColor(text.isEmpty ? .clear : .primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(minHeight: 36, maxHeight: .infinity)
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
