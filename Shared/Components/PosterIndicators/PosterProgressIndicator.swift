//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

// TODO: report indicator height, rather than

struct ProgressIndicator: View {

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
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: .bottomLeading
                )
        }
        .frame(height: 6)
    }

    @ViewBuilder
    private var regularView: some View {
        VStack(alignment: .leading, spacing: 5) {

            Text(title)
                .font(.system(.footnote, design: .rounded))
                .fontWeight(.medium)

            ProgressView(value: progress)
                .progressViewStyle(.playback)
                .foregroundStyle(.white)
                .frame(height: 6)
        }
        .padding(.bottom, 5)
        .padding(.horizontal, 5)
        .background(extendedBy: .init(top: 5, leading: 0, bottom: 0, trailing: 0)) {
            Rectangle()
                .fill(Color.black)
                .maskLinearGradient {
                    (location: 0, opacity: 0)
                    (location: 0.5, opacity: 0.7)
                    (location: 1, opacity: 1)
                }
        }
        .colorScheme(.dark)
    }

    var body: some View {
        if posterDisplayType != .landscape {
            compactView
        } else {
            regularView
        }
    }
}
