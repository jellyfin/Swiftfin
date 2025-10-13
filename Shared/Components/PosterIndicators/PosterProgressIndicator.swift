//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct PosterProgressBar: View {

    @Default(.accentColor)
    private var accentColor

    let title: String
    let progress: Double
    let posterDisplayType: PosterDisplayType

    @ViewBuilder
    private var compactView: some View {
        ContainerRelativeView(
            alignment: .bottomLeading,
            ratio: .init(width: progress, height: 1)
        ) {
            Rectangle()
                .fill(accentColor)
                .frame(height: 8)
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: .bottomLeading
                )
        }
    }

    @ViewBuilder
    private var regularView: some View {
        ContainerRelativeView(
            ratio: .init(width: 0.95, height: 0.9)
        ) {
            VStack(alignment: .leading, spacing: 5) {

                Text(title)
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
//                    .foregroundStyle(Color(uiColor: UIColor.lightText))

                ProgressView(value: progress)
                    .progressViewStyle(.playback)
                    .foregroundStyle(.white)
                    .frame(height: 5)
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .bottom
            )
        }
        .background(alignment: .bottom) {
            Rectangle()
                .fill(Color.black)
                .maskLinearGradient {
                    (location: 0, opacity: 0)
                    (location: 1, opacity: 1)
                }
                .frame(height: 50)
        }
    }

    var body: some View {
        CompactOrRegularView(
            isCompact: posterDisplayType != .landscape
        ) {
            compactView
        } regularView: {
            regularView
        }
    }
}
