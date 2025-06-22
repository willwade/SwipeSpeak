//
//  SentenceHistoryView.swift
//  SwipeSpeak
//
//  Created by SwiftUI Migration on 22/06/2025.
//  Copyright © 2025 TeamGleason. All rights reserved.
//

import SwiftUI

/// SwiftUI view for managing sentence history
struct SentenceHistoryView: View {
    @ObservedObject private var userPreferences = UserPreferences.shared
    @State private var showingClearAlert = false
    @State private var isEditing = false
    
    // Environment for navigation
    @Environment(\.dismiss) private var dismiss
    
    // Date formatter for displaying sentence dates
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        NavigationView {
            Group {
                if userPreferences.sentenceHistory.isEmpty {
                    emptyStateView
                } else {
                    sentenceListView
                }
            }
            .navigationTitle("Sentence History")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if !userPreferences.sentenceHistory.isEmpty {
                        EditButton()
                    }
                }
            }
            .environment(\.editMode, isEditing ? .constant(.active) : .constant(.inactive))
        }
        .alert("Clear Sentence History", isPresented: $showingClearAlert) {
            Button("Clear", role: .destructive) {
                clearHistory()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to clear the sentence history?")
        }
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "text.bubble")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("No History")
                    .font(.title)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text("When you create sentences you will see them here.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Sentence List View
    
    private var sentenceListView: some View {
        List {
            // Sentence history section
            Section {
                ForEach(Array(userPreferences.sentenceHistory.enumerated()), id: \.offset) { index, sentenceData in
                    SentenceRowView(
                        sentenceData: sentenceData,
                        dateFormatter: dateFormatter,
                        onSpeak: { sentence in
                            speakSentence(sentence)
                        }
                    )
                    .accessibilityElement(children: .combine)
                    .accessibilityAction(named: "Speak") {
                        if let sentence = sentenceData[SentenceKeys.sentence] as? String {
                            speakSentence(sentence)
                        }
                    }
                }
                .onDelete(perform: deleteSentences)
            }
            
            // Clear all section (only show when not editing and has sentences)
            if !isEditing && !userPreferences.sentenceHistory.isEmpty {
                Section {
                    Button("Clear All History") {
                        showingClearAlert = true
                    }
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .accessibilityLabel("Clear all sentence history")
                    .accessibilityHint("This will permanently delete all saved sentences")
                }
            }
        }
        .listStyle(.insetGrouped)
        .environment(\.editMode, isEditing ? .constant(.active) : .constant(.inactive))
    }
    
    // MARK: - Actions
    
    private func deleteSentences(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) {
            userPreferences.removeSentence(index)
        }
        
        // Provide haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    private func clearHistory() {
        userPreferences.clearSentenceHistory()
        
        // Provide haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
    }
    
    private func speakSentence(_ sentence: String) {
        guard !sentence.isEmpty else { return }
        SpeechSynthesizer.shared.speak(sentence)
        
        // Provide haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
}

// MARK: - Sentence Row View

private struct SentenceRowView: View {
    let sentenceData: [String: Any]
    let dateFormatter: DateFormatter
    let onSpeak: (String) -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                if let sentence = sentenceData[SentenceKeys.sentence] as? String {
                    Text(sentence)
                        .font(.body)
                        .foregroundColor(.primary)
                        .lineLimit(3)
                    
                    if let date = sentenceData[SentenceKeys.date] as? Date {
                        Text(dateFormatter.string(from: date))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            Button {
                if let sentence = sentenceData[SentenceKeys.sentence] as? String {
                    onSpeak(sentence)
                }
            } label: {
                Image(systemName: "speaker.2")
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Speak sentence")
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if let sentence = sentenceData[SentenceKeys.sentence] as? String {
                onSpeak(sentence)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SentenceHistoryView()
}

#Preview("Empty State") {
    // Preview with empty history
    SentenceHistoryView()
        .onAppear {
            UserPreferences.shared.clearSentenceHistory()
        }
}

#Preview("With History") {
    // Preview with sample sentences
    SentenceHistoryView()
        .onAppear {
            UserPreferences.shared.clearSentenceHistory()
            UserPreferences.shared.addSentence("Hello world")
            UserPreferences.shared.addSentence("This is a test sentence")
            UserPreferences.shared.addSentence("SwiftUI is great")
        }
}
