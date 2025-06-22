//
//  SwipeGestureView.swift
//  SwipeSpeak
//
//  Created by SwiftUI Migration on 22/06/2025.
//  Copyright © 2025 TeamGleason. All rights reserved.
//

import SwiftUI

/// Advanced gesture recognition view that mimics UIKit SwipeView behavior
struct SwipeGestureView<Content: View>: View {
    let content: Content
    let numberOfKeys: Int
    let onTap: (Int) -> Void
    let onSwipe: (Int) -> Void
    let onLongPress: () -> Void
    
    @State private var swipeDirectionList: [Int] = []
    @State private var gestureStartTime: Date?
    @State private var velocityHistory: [CGSize] = []
    @State private var isLongPressing: Bool = false
    
    // Gesture thresholds
    private let minimumSwipeDistance: CGFloat = 10
    private let minimumSwipeVelocity: CGFloat = 50
    private let longPressDelay: TimeInterval = 0.5
    private let velocityHistoryLimit: Int = 10
    
    init(numberOfKeys: Int, 
         onTap: @escaping (Int) -> Void,
         onSwipe: @escaping (Int) -> Void,
         onLongPress: @escaping () -> Void,
         @ViewBuilder content: () -> Content) {
        self.numberOfKeys = numberOfKeys
        self.onTap = onTap
        self.onSwipe = onSwipe
        self.onLongPress = onLongPress
        self.content = content()
    }
    
    var body: some View {
        content
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        handleDragChanged(value)
                    }
                    .onEnded { value in
                        handleDragEnded(value)
                    }
            )
            .simultaneousGesture(
                LongPressGesture(minimumDuration: longPressDelay)
                    .onEnded { _ in
                        handleLongPress()
                    }
            )
    }
    
    // MARK: - Gesture Handling
    
    private func handleDragChanged(_ value: DragGesture.Value) {
        if gestureStartTime == nil {
            gestureStartTime = Date()
            swipeDirectionList = Array(repeating: 0, count: numberOfKeys)
            velocityHistory.removeAll()
            isLongPressing = false
        }
        
        // Track velocity over time for more accurate direction detection
        let currentVelocity = CGSize(
            width: value.velocity.x,
            height: value.velocity.y
        )
        
        velocityHistory.append(currentVelocity)
        if velocityHistory.count > velocityHistoryLimit {
            velocityHistory.removeFirst()
        }
        
        // Calculate key index based on current velocity
        let keyIndex = SwipeDirection.keyIndex(for: currentVelocity, numberOfKeys: numberOfKeys)
        if keyIndex >= 0 && keyIndex < swipeDirectionList.count {
            swipeDirectionList[keyIndex] += 1
        }
    }
    
    private func handleDragEnded(_ value: DragGesture.Value) {
        defer {
            gestureStartTime = nil
            velocityHistory.removeAll()
            isLongPressing = false
        }
        
        let translation = value.translation
        let finalVelocity = value.velocity
        
        // Calculate gesture metrics
        let dragDistance = sqrt(translation.x * translation.x + translation.y * translation.y)
        let velocityMagnitude = sqrt(finalVelocity.x * finalVelocity.x + finalVelocity.y * finalVelocity.y)
        
        // Determine if this was a tap or swipe
        if dragDistance < minimumSwipeDistance && velocityMagnitude < minimumSwipeVelocity {
            // This was a tap - determine which key was tapped
            handleTapGesture(at: value.startLocation)
        } else {
            // This was a swipe - find the majority direction
            handleSwipeGesture()
        }
    }
    
    private func handleTapGesture(at location: CGPoint) {
        // For tap gestures, we would need to determine which key was tapped
        // This would require coordinate mapping to keyboard layout
        // For now, default to key 0
        onTap(0)
    }
    
    private func handleSwipeGesture() {
        guard let maxCount = swipeDirectionList.max(), maxCount > 0 else {
            return
        }
        
        guard let majorityDirection = swipeDirectionList.firstIndex(of: maxCount) else {
            return
        }
        
        onSwipe(majorityDirection)
    }
    
    private func handleLongPress() {
        if !isLongPressing {
            isLongPressing = true
            onLongPress()
        }
    }
}

// MARK: - Enhanced Gesture Recognition

/// Enhanced gesture recognition that provides more sophisticated tracking
struct EnhancedGestureRecognizer {
    
    /// Analyze velocity history to determine the most consistent direction
    static func analyzeVelocityHistory(_ velocityHistory: [CGSize], numberOfKeys: Int) -> Int? {
        guard !velocityHistory.isEmpty else { return nil }
        
        var directionCounts = Array(repeating: 0, count: numberOfKeys)
        
        // Weight recent velocities more heavily
        for (index, velocity) in velocityHistory.enumerated() {
            let weight = Double(index + 1) / Double(velocityHistory.count)
            let keyIndex = SwipeDirection.keyIndex(for: velocity, numberOfKeys: numberOfKeys)
            
            if keyIndex >= 0 && keyIndex < directionCounts.count {
                directionCounts[keyIndex] += Int(weight * 10) // Scale for integer math
            }
        }
        
        guard let maxCount = directionCounts.max(), maxCount > 0 else {
            return nil
        }
        
        return directionCounts.firstIndex(of: maxCount)
    }
    
    /// Calculate gesture confidence based on consistency
    static func calculateGestureConfidence(_ velocityHistory: [CGSize], numberOfKeys: Int) -> Double {
        guard velocityHistory.count > 1 else { return 0.0 }
        
        let directions = velocityHistory.map { SwipeDirection.keyIndex(for: $0, numberOfKeys: numberOfKeys) }
        let uniqueDirections = Set(directions)
        
        // Higher confidence when directions are consistent
        let consistency = 1.0 - (Double(uniqueDirections.count - 1) / Double(numberOfKeys - 1))
        
        // Higher confidence with more data points
        let dataConfidence = min(1.0, Double(velocityHistory.count) / 5.0)
        
        return consistency * dataConfidence
    }
    
    /// Smooth velocity using moving average
    static func smoothVelocity(_ velocityHistory: [CGSize]) -> CGSize {
        guard !velocityHistory.isEmpty else { return .zero }
        
        let recentVelocities = Array(velocityHistory.suffix(3)) // Use last 3 velocities
        let avgX = recentVelocities.map { $0.width }.reduce(0, +) / CGFloat(recentVelocities.count)
        let avgY = recentVelocities.map { $0.height }.reduce(0, +) / CGFloat(recentVelocities.count)
        
        return CGSize(width: avgX, height: avgY)
    }
}

// MARK: - Preview

#Preview {
    SwipeGestureView(
        numberOfKeys: 4,
        onTap: { keyIndex in print("Tapped key \(keyIndex)") },
        onSwipe: { keyIndex in print("Swiped to key \(keyIndex)") },
        onLongPress: { print("Long press detected") }
    ) {
        Rectangle()
            .fill(Color.blue.opacity(0.3))
            .frame(width: 200, height: 200)
            .overlay(
                Text("Swipe Gesture Area")
                    .foregroundColor(.white)
                    .font(.headline)
            )
    }
    .padding()
}
