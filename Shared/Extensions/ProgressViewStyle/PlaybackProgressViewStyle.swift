//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct PlaybackProgressViewStyle: ProgressViewStyle {

    enum CornerStyle {
        case round
        case square
    }

    @State
    private var contentSize: CGSize = .zero

    var secondaryProgress: Double?
    var cornerStyle: CornerStyle

    @ViewBuilder
    private func buildProgressFill(for progress: Double, isPrimary: Bool) -> some View {
        let clampedProgress = clamp(progress, min: 0, max: 1)
        let cornerRadius = cornerStyle == .round ? contentSize.height / 2 : 0

        Capsule()
            .fill(
                isPrimary
                    ? AnyShapeStyle(Color.white)
                    : AnyShapeStyle(Color.white.opacity(0.4))
            )
            .frame(width: max(contentSize.height, contentSize.width * clampedProgress))
            .shadow(
                color: isPrimary ? Color.white.opacity(0.3) : Color.clear,
                radius: isPrimary ? 8 : 0,
                y: 0
            )
    }

    func makeBody(configuration: Configuration) -> some View {
        ZStack(alignment: .leading) {
            // Background track - solid dark color to avoid color bleed from video
            Capsule()
                .fill(Color.white.opacity(0.2))

            // Secondary progress (buffered)
            if let secondaryProgress, secondaryProgress > 0 {
                buildProgressFill(for: secondaryProgress, isPrimary: false)
            }

            // Primary progress
            if let fractionCompleted = configuration.fractionCompleted {
                buildProgressFill(for: fractionCompleted, isPrimary: true)
            }
        }
        .clipShape(Capsule())
        .trackingSize($contentSize)
    }
}
