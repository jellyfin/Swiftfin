//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation
import SwiftUI

extension UserDashboardView {
    struct TimelineSection: View {
        let playbackPercentage: Double
        let transcodingPercentage: Double
        let playbackColor: Color
        let transcodingColor: Color?

        init(
            playbackPercentage: Double,
            transcodingPercentage: Double = 0.0,
            playbackColor: Color = .accentColor,
            transcodingColor: Color = .gray
        ) {
            self.playbackPercentage = min(max(playbackPercentage, 0.0), 1.0)
            self.transcodingPercentage = min(max(transcodingPercentage, 0.0), 1.0)
            self.playbackColor = playbackColor
            self.transcodingColor = transcodingColor
        }

        // MARK: Body

        @ViewBuilder
        var body: some View {
            ZStack(alignment: .leading) {
                if transcodingPercentage > 0.0 {
                    ProgressView(value: transcodingPercentage, total: 1.0)
                        .progressViewStyle(
                            LinearProgressViewStyle(tint: transcodingColor ?? .gray)
                        )
                        .scaleEffect(x: 1, y: 2)
                }

                ProgressView(value: playbackPercentage, total: 1.0)
                    .progressViewStyle(
                        LinearProgressViewStyle(tint: playbackColor)
                    )
                    .scaleEffect(x: 1, y: 2)
            }
            .frame(height: 6)
        }
    }
}
