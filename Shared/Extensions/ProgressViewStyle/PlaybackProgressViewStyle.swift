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
    private func buildCapsule(for progress: Double) -> some View {
        Rectangle()
            .cornerRadius(
                cornerStyle == .round ? contentSize.height / 2 : 0,
                corners: [.topLeft, .bottomLeft]
            )
            .frame(width: contentSize.width * clamp(progress, min: 0, max: 1) + contentSize.height)
            .offset(x: -contentSize.height)
    }

    func makeBody(configuration: Configuration) -> some View {
        Capsule()
            .foregroundStyle(.secondary)
            .opacity(0.2)
            .overlay(alignment: .leading) {
                ZStack(alignment: .leading) {

                    if let secondaryProgress,
                       secondaryProgress > 0
                    {
                        buildCapsule(for: secondaryProgress)
                            .foregroundStyle(.tertiary)
                    }

                    if let fractionCompleted = configuration.fractionCompleted {
                        buildCapsule(for: fractionCompleted)
                            .foregroundStyle(.primary)
                    }
                }
            }
            .trackingSize($contentSize)
            .mask {
                Capsule()
            }
    }
}
