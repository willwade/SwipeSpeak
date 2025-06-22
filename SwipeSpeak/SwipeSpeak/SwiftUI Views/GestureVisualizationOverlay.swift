//
//  GestureVisualizationOverlay.swift
//  SwipeSpeak
//
//  Created by SwiftUI Migration on 2025-01-22.
//  Copyright © 2025 TeamGleason. All rights reserved.
//

import SwiftUI

/// Gesture visualization overlay that shows red line during swipe gestures
struct GestureVisualizationOverlay: View {
    @ObservedObject var gestureManager: GestureOverlayManager
    
    var body: some View {
        Canvas { context, size in
            // Draw the gesture path as a red line
            if !gestureManager.gesturePath.isEmpty {
                var path = Path()
                
                for (index, point) in gestureManager.gesturePath.enumerated() {
                    if index == 0 {
                        path.move(to: point)
                    } else {
                        path.addLine(to: point)
                    }
                }
                
                context.stroke(
                    path,
                    with: .color(.red),
                    style: StrokeStyle(lineWidth: 4.0, lineCap: .round, lineJoin: .round)
                )
            }
        }
        .allowsHitTesting(false) // Allow touches to pass through
        .animation(.easeOut(duration: 0.1), value: gestureManager.gesturePath)
    }
}

/// Manager for gesture overlay state
@MainActor
class GestureOverlayManager: ObservableObject {
    @Published var gesturePath: [CGPoint] = []
    @Published var isGestureActive: Bool = false
    
    private var clearTimer: Timer?
    
    /// Update gesture path during drag
    func updateGesture(_ value: DragGesture.Value) {
        if !isGestureActive {
            isGestureActive = true
            gesturePath = [value.startLocation]
        }
        
        gesturePath.append(value.location)
        
        // Limit path length for performance
        if gesturePath.count > 100 {
            gesturePath.removeFirst()
        }
    }
    
    /// End gesture and clear path after delay
    func endGesture(_ value: DragGesture.Value) {
        isGestureActive = false
        
        // Clear the path after a short delay
        clearTimer?.invalidate()
        clearTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
            Task { @MainActor in
                self.gesturePath.removeAll()
            }
        }
    }
    
    /// Clear gesture path immediately
    func clearGesture() {
        gesturePath.removeAll()
        isGestureActive = false
        clearTimer?.invalidate()
    }
    
    deinit {
        clearTimer?.invalidate()
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Rectangle()
            .fill(Color.gray.opacity(0.1))
            .frame(width: 300, height: 200)
        
        GestureVisualizationOverlay(gestureManager: GestureOverlayManager())
    }
    .padding()
}
