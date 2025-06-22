//
//  UserAddedWordsView.swift
//  SwipeSpeak
//
//  Created by SwiftUI Migration on 22/06/2025.
//  Copyright © 2025 TeamGleason. All rights reserved.
//

import SwiftUI

/// SwiftUI view for managing user-added words
struct UserAddedWordsView: View {
    @ObservedObject private var userPreferences = UserPreferences.shared
    @State private var showingAddWordAlert = false
    @State private var newWord = ""
    @State private var isEditing = false
    
    // Environment for navigation
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Group {
                if userPreferences.userAddedWords.isEmpty {
                    emptyStateView
                } else {
                    wordListView
                }
            }
            .navigationTitle("Added Words")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button("Add") {
                        showingAddWordAlert = true
                    }
                    .accessibilityLabel("Add new word")
                    
                    if !userPreferences.userAddedWords.isEmpty {
                        EditButton()
                    }
                }
            }
            .environment(\.editMode, isEditing ? .constant(.active) : .constant(.inactive))
        }
        .alert("Add Word", isPresented: $showingAddWordAlert) {
            TextField("Enter word", text: $newWord)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            
            Button("Add") {
                addWord()
            }
            .disabled(!isWordValid(newWord) || userPreferences.userAddedWords.contains(newWord))
            
            Button("Cancel", role: .cancel) {
                newWord = ""
            }
        } message: {
            Text("Please do not include punctuations or spaces")
        }
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "text.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("No Added Words")
                    .font(.title)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text("When you add words you will see them here.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Button("Add Word") {
                showingAddWordAlert = true
            }
            .buttonStyle(.borderedProminent)
            .accessibilityLabel("Add your first word")
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Word List View
    
    private var wordListView: some View {
        List {
            ForEach(Array(userPreferences.userAddedWords.enumerated()), id: \.offset) { index, word in
                HStack {
                    Text(word)
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button {
                        speakWord(word)
                    } label: {
                        Image(systemName: "speaker.2")
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Speak \(word)")
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    speakWord(word)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Word: \(word)")
                .accessibilityHint("Tap to speak this word")
                .accessibilityAction(named: "Speak") {
                    speakWord(word)
                }
            }
            .onDelete(perform: deleteWords)
        }
        .listStyle(.insetGrouped)
        .environment(\.editMode, isEditing ? .constant(.active) : .constant(.inactive))
    }
    
    // MARK: - Actions
    
    private func addWord() {
        let trimmedWord = newWord.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isWordValid(trimmedWord) else { return }
        guard !userPreferences.userAddedWords.contains(trimmedWord) else { return }
        
        userPreferences.addWord(trimmedWord)
        newWord = ""
        
        // Provide haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    private func deleteWords(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) {
            userPreferences.removeWord(index)
        }
        
        // Provide haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    private func speakWord(_ word: String) {
        guard !word.isEmpty else { return }
        SpeechSynthesizer.shared.speak(word)
        
        // Provide haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
}

// MARK: - Preview

#Preview {
    UserAddedWordsView()
}

#Preview("Empty State") {
    // Preview with empty words list
    UserAddedWordsView()
        .onAppear {
            UserPreferences.shared.clearWords()
        }
}

#Preview("With Words") {
    // Preview with sample words
    UserAddedWordsView()
        .onAppear {
            UserPreferences.shared.clearWords()
            UserPreferences.shared.addWord("hello")
            UserPreferences.shared.addWord("world")
            UserPreferences.shared.addWord("test")
        }
}
