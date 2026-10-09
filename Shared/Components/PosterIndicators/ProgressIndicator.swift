//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct ProgressIndicator: View {

    @Default(.accentColor)
    private var accentColor

    let title: String
    let progress: Double
    let posterDisplayType: PosterDisplayType

    private let indicators: [QuadrantItem]

    init(
        title: String,
        progress: Double,
        posterDisplayType: PosterDisplayType,
        @ArrayBuilder<QuadrantItem> indicators: () -> [QuadrantItem]
    ) {
        self.title = title
        self.progress = progress
        self.posterDisplayType = posterDisplayType
        self.indicators = indicators()
    }

    private var inset: CGFloat {
        UIDevice.isTV ? 10 : 6
    }

    private var normalizedProgress: Double {
        progress.isFinite ? clamp(progress, min: 0, max: 1) : 0
    }

    @ViewBuilder
    private var progressBar: some View {
        ProgressView(value: normalizedProgress)
            .progressViewStyle(.playback)
            .foregroundStyle(accentColor)
            .frame(height: 6)
            .padding(.horizontal, 5)
            .padding(.bottom, 5)
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private var compactProgressBar: some View {
        Rectangle()
            .fill(accentColor)
            .scaleEffect(x: normalizedProgress, y: 1, anchor: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 6)
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private var runtime: some View {
        Text(title)
            .font(.system(.footnote, design: .rounded, weight: .semibold))
            .monospacedDigit()
            .foregroundStyle(.white)
            .lineLimit(1)
            .padding(.horizontal, UIDevice.isTV ? 12 : 8)
            .padding(.vertical, UIDevice.isTV ? 5 : 3)
            .background(.black.opacity(0.72), in: Capsule())
            .overlay {
                Capsule().strokeBorder(.white.opacity(0.18), lineWidth: 0.5)
            }
    }

    @ViewBuilder
    private var indicatorTrack: some View {
        Quadrant(.bottomTrailing, isFloating: true) {
            indicators
        }
    }

    @ViewBuilder
    private func landscapeView(showsIndicators: Bool) -> some View {
        VStack(spacing: inset) {
            HStack(spacing: inset) {
                runtime

                Spacer(minLength: 0)

                if showsIndicators {
                    indicatorTrack
                }
            }
            .padding(.horizontal, inset)

            progressBar
        }
    }

    @ViewBuilder
    private func compactView(showsIndicators: Bool) -> some View {
        VStack(alignment: .trailing, spacing: inset) {
            if showsIndicators {
                indicatorTrack
                    .padding(.horizontal, inset)
            }

            // Badges sit above the bar so progress uses the full poster width.
            compactProgressBar
        }
    }

    var body: some View {
        Group {
            if posterDisplayType == .landscape {
                landscapeView(showsIndicators: !indicators.isEmpty)
            } else {
                compactView(showsIndicators: !indicators.isEmpty)
            }
        }
        .background {
            LinearGradient(
                colors: [.clear, .black.opacity(0.65)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .colorScheme(.dark)
    }
}
