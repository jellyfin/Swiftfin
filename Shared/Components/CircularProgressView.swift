//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct CircularProgressView: View {

    @Default(.accentColor)
    private var accentColor

    private let progress: Double
    private let size: CGFloat
    private let strokeWidth: CGFloat
    private let backgroundColor: Color
    private let progressColor: Color
    private let showBackground: Bool
    private let animation: Animation

    init(
        progress: Double,
        size: CGFloat = 24,
        strokeWidth: CGFloat = 4,
        backgroundColor: Color? = nil,
        progressColor: Color? = nil,
        showBackground: Bool = true,
        animation: Animation = .linear(duration: 0.1)
    ) {
        self.progress = max(0, min(1, progress))
        self.size = size
        self.strokeWidth = strokeWidth
        self.backgroundColor = backgroundColor ?? Color.gray.opacity(0.4)
        self.progressColor = progressColor ?? .accentColor
        self.showBackground = showBackground
        self.animation = animation
    }

    var body: some View {
        ZStack {
            if showBackground {
                // Background circle
                Circle()
                    .stroke(backgroundColor, lineWidth: strokeWidth)
            }

            // Progress circle
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    progressColor,
                    style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(animation, value: progress)
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    VStack(spacing: 20) {
        HStack(spacing: 20) {
            CircularProgressView(progress: 0.25)
            CircularProgressView(progress: 0.5)
            CircularProgressView(progress: 0.75)
            CircularProgressView(progress: 1.0)
        }

        HStack(spacing: 20) {
            CircularProgressView(progress: 0.3, size: 32, strokeWidth: 6)
            CircularProgressView(progress: 0.6, size: 32, strokeWidth: 6)
            CircularProgressView(progress: 0.9, size: 32, strokeWidth: 6)
        }

        HStack(spacing: 20) {
            CircularProgressView(
                progress: 0.4,
                size: 20,
                strokeWidth: 2,
                backgroundColor: .blue.opacity(0.3),
                progressColor: .blue
            )
            CircularProgressView(
                progress: 0.7,
                size: 20,
                strokeWidth: 2,
                backgroundColor: .green.opacity(0.3),
                progressColor: .green
            )
            CircularProgressView(
                progress: 0.2,
                size: 20,
                strokeWidth: 2,
                backgroundColor: .orange.opacity(0.3),
                progressColor: .orange
            )
        }

        CircularProgressView(progress: 0.8, size: 48, strokeWidth: 8)
    }
    .padding()
}
