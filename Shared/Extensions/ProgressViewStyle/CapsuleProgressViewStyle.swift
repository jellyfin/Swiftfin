//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct CapsuleProgressViewStyle: ProgressViewStyle {

    enum CornerStyle {
        case round
        case square
    }

    @State
    private var contentSize: CGSize = .zero

    var secondaryProgress: Double?
    var cornerStyle: CornerStyle
    var tickProgress: Double?
    var showsProgress = true

    @ViewBuilder
    private func buildCapsule(for progress: Double) -> some View {
        let width = contentSize.width.isFinite ? max(0, contentSize.width) : 0
        let height = contentSize.height.isFinite ? max(0, contentSize.height) : 0
        let normalizedProgress = progress.isFinite ? clamp(progress, min: 0, max: 1) : 0

        Rectangle()
            .cornerRadius(
                cornerStyle == .round ? height / 2 : 0,
                corners: [.topLeft, .bottomLeft]
            )
            .frame(width: width * normalizedProgress + height)
            .offset(x: -height)
    }

    func makeBody(configuration: Configuration) -> some View {
        Capsule()
            .foregroundStyle(.secondary)
            .opacity(0.2)
            .overlay(alignment: .leading) {
                ZStack(alignment: .leading) {

                    if showsProgress {
                        if let secondaryProgress, secondaryProgress > (configuration.fractionCompleted ?? 0) {
                            buildCapsule(for: secondaryProgress)
                                .foregroundStyle(.tertiary)
                        }

                        if let fractionCompleted = configuration.fractionCompleted {
                            buildCapsule(for: fractionCompleted)
                                .foregroundStyle(.primary)
                        }
                    }

                    if let tickProgress, tickProgress.isFinite {
                        let width = contentSize.width.isFinite ? max(0, contentSize.width) : 0
                        let tickWidth = min(3, width)
                        let offset = clamp(width * tickProgress - tickWidth / 2, min: 0, max: width - tickWidth)

                        Rectangle()
                            .foregroundStyle(.primary)
                            .frame(width: tickWidth)
                            .offset(x: offset)
                    }
                }
            }
            .trackingSize($contentSize)
            .clipShape(Capsule())
            .overlay {
                Capsule().strokeBorder(.white.opacity(0.18), lineWidth: 0.5)
            }
    }
}
