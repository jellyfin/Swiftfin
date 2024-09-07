//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

extension ActiveSessionRowView {
    struct ContentSection: View {
        @Default(.Customization.Library.posterType)
        private var posterType

        let item: BaseItemDto?

        init(session: SessionInfo) {
            self.item = session.nowPlayingItem
        }

        var body: some View {
            HStack(alignment: .top) {
                if let contentItem = item {
                    // TODO: Fix this weird switch case
                    switch posterType {
                    case .portrait:
                        ImageView(contentItem.portraitImageSources().first!)
                            .frame(width: 60, height: 90)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    case .landscape:
                        ImageView(contentItem.landscapeImageSources().first!)
                            .frame(width: 160, height: 90)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    contentView
                }
            }
        }

        private var contentView: some View {
            VStack(alignment: .leading) {
                if let contentItem = item {
                    Text(self.getTitle(item: contentItem))
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(2)
                    Text(self.getParent(item: contentItem) ?? "")
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    Text(self.getEpisode(item: contentItem) ?? "")
                        .foregroundColor(.secondary)
                        .lineLimit(1)
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
