//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct PosterIndicatorsOverlay: View {

    let item: BaseItemDto
    let indicators: PosterIndicator
    let posterDisplayType: PosterDisplayType

    var body: some View {
        VStack(spacing: 0) {
            ZStack {

                if indicators.contains(.unplayed), item.canBePlayed, item.userData?.isPlayed == false {
                    UnplayedIndicator()
                }

                HStack {
                    if indicators.contains(.favorited), item.userData?.isFavorite == true {
                        FavoriteIndicator()
                    }

                    if indicators.contains(.played), item.userData?.isPlayed == true {
                        PlayedIndicator()
                    }
                }
                .padding(5)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .zIndex(10)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if indicators.contains(.progress),
               let progress = item.progress,
               let runtime = item.runtime,
               let playbackPosition = item.userData?.playbackPosition,
               playbackPosition < runtime
            {
                // TODO: have "x left" string
                ProgressIndicator(
                    title: (runtime - playbackPosition).formatted(.hourMinuteAbbreviated),
                    progress: progress,
                    posterDisplayType: posterDisplayType
                )
                .zIndex(5)
            }
        }
    }
}
