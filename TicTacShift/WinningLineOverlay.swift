//
//  WinningLineOverlay.swift
//  TicTacShift
//
//  Winning line overlay for the game board
//

import SwiftUI

struct WinningLineOverlay: View {
    let winningLine: WinningLine?
    let squareSize: CGFloat = 90
    let spacing: CGFloat = 6
    @State private var animationProgress: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    var body: some View {
        ZStack {
            if let line = winningLine {
                WinningLineShape(
                    line: line,
                    squareSize: squareSize,
                    spacing: spacing,
                    progress: animationProgress
                )
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.yellow.opacity(0.9),
                            Color.yellow,
                            Color.orange
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(
                        lineWidth: 6,
                        lineCap: .round
                    )
                )
                .shadow(color: .yellow, radius: 10)
                .shadow(color: .yellow.opacity(0.5), radius: 20)
            }
        }
        .onAppear {
            if !reduceMotion {
                withAnimation(.easeInOut(duration: 0.8).delay(0.2)) {
                    animationProgress = 1.0
                }
            } else {
                animationProgress = 1.0
            }
        }
    }
}

struct WinningLineShape: Shape {
    let line: WinningLine
    let squareSize: CGFloat
    let spacing: CGFloat
    let progress: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Calculate grid dimensions
        let totalWidth = 3 * squareSize + 2 * spacing
        let totalHeight = 3 * squareSize + 2 * spacing
        
        // Center the grid in the rect
        let offsetX = (rect.width - totalWidth) / 2
        let offsetY = (rect.height - totalHeight) / 2
        
        let startPoint = getLineStartPoint(offsetX: offsetX, offsetY: offsetY)
        let endPoint = getLineEndPoint(offsetX: offsetX, offsetY: offsetY)
        
        // Animate the line drawing
        let currentEndPoint = CGPoint(
            x: startPoint.x + (endPoint.x - startPoint.x) * progress,
            y: startPoint.y + (endPoint.y - startPoint.y) * progress
        )
        
        path.move(to: startPoint)
        path.addLine(to: currentEndPoint)
        
        return path
    }
    
    private func getLineStartPoint(offsetX: CGFloat, offsetY: CGFloat) -> CGPoint {
        let centerOffset = squareSize / 2
        
        switch line.type {
        case .horizontal:
            let row = line.index
            let y = offsetY + CGFloat(row) * (squareSize + spacing) + centerOffset
            return CGPoint(x: offsetX + centerOffset, y: y)
            
        case .vertical:
            let col = line.index  
            let x = offsetX + CGFloat(col) * (squareSize + spacing) + centerOffset
            return CGPoint(x: x, y: offsetY + centerOffset)
            
        case .diagonal:
            if line.index == 0 { // Main diagonal (\)
                return CGPoint(x: offsetX + centerOffset, y: offsetY + centerOffset)
            } else { // Anti diagonal (/)
                return CGPoint(x: offsetX + 2 * (squareSize + spacing) + centerOffset, y: offsetY + centerOffset)
            }
        }
    }
    
    private func getLineEndPoint(offsetX: CGFloat, offsetY: CGFloat) -> CGPoint {
        let centerOffset = squareSize / 2
        
        switch line.type {
        case .horizontal:
            let row = line.index
            let y = offsetY + CGFloat(row) * (squareSize + spacing) + centerOffset
            return CGPoint(x: offsetX + 2 * (squareSize + spacing) + centerOffset, y: y)
            
        case .vertical:
            let col = line.index
            let x = offsetX + CGFloat(col) * (squareSize + spacing) + centerOffset
            return CGPoint(x: x, y: offsetY + 2 * (squareSize + spacing) + centerOffset)
            
        case .diagonal:
            if line.index == 0 { // Main diagonal (\)
                return CGPoint(
                    x: offsetX + 2 * (squareSize + spacing) + centerOffset,
                    y: offsetY + 2 * (squareSize + spacing) + centerOffset
                )
            } else { // Anti diagonal (/)
                return CGPoint(
                    x: offsetX + centerOffset,
                    y: offsetY + 2 * (squareSize + spacing) + centerOffset
                )
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black.opacity(0.1)
        
        // Mock game board
        VStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { row in
                HStack(spacing: 6) {
                    ForEach(0..<3, id: \.self) { col in
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 90, height: 90)
                    }
                }
            }
        }
        
        // Winning line overlay
        WinningLineOverlay(
            winningLine: WinningLine(
                type: .diagonal,
                index: 0,
                positions: [(0, 0), (1, 1), (2, 2)]
            )
        )
    }
    .frame(width: 300, height: 300)
}