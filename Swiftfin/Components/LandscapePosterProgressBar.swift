//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

// TODO: fix relative padding, or remove?
// TODO: gradient should grow/shrink with content, not relative to container

struct LandscapePosterProgressBar<Content: View>: View {

    @Default(.accentColor)
    private var accentColor

    // Scale padding depending on view width
    @State
    private var paddingScale: CGFloat = 1.0
    @State
    private var width: CGFloat = 0

    private let content: () -> Content
    private let progress: Double

    var body: some View {
        ZStack(alignment: .bottom) {

            Color.clear

            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .black.opacity(0.7), location: 1),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 40)

            VStack(alignment: .leading, spacing: 3 * paddingScale) {

                content()

                ProgressBar(progress: progress)
                    .foregroundColor(accentColor)
                    .frame(height: 3)
            }
            .padding(.horizontal, 5 * paddingScale)
            .padding(.bottom, 7 * paddingScale)
        }
        .onSizeChanged { newSize in
            width = newSize.width
        }
    }
}

extension LandscapePosterProgressBar where Content == Text {

    init(
        title: String,
        progress: Double
    ) {
        self.init(
            content: {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.white)
            },
            progress: progress
        )
    }
}

extension LandscapePosterProgressBar where Content == EmptyView {

    init(progress: Double) {
        self.init(
            content: { EmptyView() },
            progress: progress
        )
    }
}

extension LandscapePosterProgressBar {

    init(
        progress: Double,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.init(
            content: content,
            progress: progress
        )
    }
}
