//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension ActiveDevicesView {

    struct ContentSection: View {

        let item: BaseItemDto

        // MARK: - Body

        var body: some View {
            VStack(alignment: .leading) {

                if let parent = item.parentTitle {
                    Text(parent)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Text(item.displayTitle)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                if let subtitle = item.subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.bottom)
        }

        // MARK: - Get Content Title

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

            return baseName
        }

        // MARK: - Get Content Parent

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
    }
}
