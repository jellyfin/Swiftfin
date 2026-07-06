//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

struct PosterIndicatorsOverlay: View {

    let item: BaseItemDto
    let indicators: PosterIndicator
    let posterDisplayType: PosterDisplayType

    private var indicatorSize: CGFloat {
        UIDevice.isTV ? 45 : 25
    }

    private var showsUnplayedIndicator: Bool {
        indicators.contains(.unplayed) &&
            item.canBePlayed &&
            !item.isLiveStream &&
            item.userData?.isPlayed == false &&
            (item.userData?.playbackPositionTicks ?? 0) == 0
    }

    private var showsProgressIndicator: Bool {
        indicators.contains(.progress) &&
            item.progressLabel != nil &&
            item.userData?.isPlayed != true
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                if showsUnplayedIndicator {
                    UnplayedIndicator()
                        .frame(width: indicatorSize, height: indicatorSize)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                }

                HStack(spacing: 5) {
                    if indicators.contains(.favorited), item.userData?.isFavorite == true {
                        FavoriteIndicator()
                            .frame(width: indicatorSize, height: indicatorSize)
                    }

                    if indicators.contains(.played),
                       item.canBePlayed,
                       !item.isLiveStream,
                       item.userData?.isPlayed == true
                    {
                        PlayedIndicator()
                            .frame(width: indicatorSize, height: indicatorSize)
                    }
                }
                .padding(3)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .zIndex(10)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if showsProgressIndicator {
                ProgressIndicator(
                    title: item.progressLabel ?? "",
                    progress: (item.userData?.playedPercentage ?? 0) / 100,
                    posterDisplayType: posterDisplayType
                )
                .zIndex(5)
            }
        }
    }
}

struct PosterSelectionOverlay: View {

    @Default(.accentColor)
    private var accentColor

    @Environment(\.isSelected)
    private var isSelected

    var body: some View {
        if isSelected {
            ContainerRelativeShape()
                .stroke(accentColor, lineWidth: UIDevice.isTV ? 12 : 8)
                .clipped()
        }
    }
}
