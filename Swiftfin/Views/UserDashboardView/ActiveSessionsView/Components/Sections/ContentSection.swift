//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension ActiveSessionsView {
    struct ContentSection: View {
        let item: BaseItemDto?

        init(session: SessionInfo) {
            self.item = session.nowPlayingItem
        }

        var body: some View {
            VStack(alignment: .leading) {
                if let contentItem = item {
                    Text(self.getTitle(item: contentItem))
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(2)
                    if let parent = self.getParent(item: contentItem) {
                        Text(parent)
                            .lineLimit(1)
                    }
                    if let episode = self.getEpisode(item: contentItem) {
                        Text(episode)
                            .lineLimit(1)
                    }
                }
            }
        }

        private func getTitle(item: BaseItemDto) -> String {
            let baseName: String

            if (item.type == .program || item.type == .recording) &&
                (item.isSeries == true || item.episodeTitle != nil)
            {
                baseName = item.episodeTitle ?? ""
            } else {
                baseName = item.name ?? ""
            }

            if item.type == .tvChannel {
                if let channelNumber = item.channelNumber {
                    return "\(channelNumber) \(baseName)"
                }
                return baseName
            }

            if item.type == .episode && item.parentIndexNumber == 0 {
                return baseName
            }

            return baseName
        }

        private func getParent(item: BaseItemDto) -> String? {
            if let artists = item.artists, !artists.isEmpty {
                return artists.first ?? ""
            } else if let seriesName = item.seriesName ?? item.album {
                return seriesName
            } else if let productionYear = item.productionYear {
                return productionYear.description
            }
            return nil
        }

        private func getEpisode(item: BaseItemDto) -> String? {
            guard item.indexNumber != nil, item.parentIndexNumber != nil else { return nil }

            var number = L10n.seasonAndEpisode(
                String(item.parentIndexNumber!),
                String(item.indexNumber!)
            )

            if let indexNumberEnd = item.indexNumberEnd {
                number += "-\(indexNumberEnd)"
            }

            return number
        }
    }
}
