//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import SwiftUI

struct SessionDisplayNameView: View {
    let item: BaseItemDto?

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .fixedSize(horizontal: false, vertical: true)

            if let parentObject = parentInfo {
                Text(parentObject)
                    .foregroundColor(.secondary)
            }

            if let episodeObject = episodeInfo {
                Text(episodeObject)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var title: String {
        guard let item = item else { return "" }

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

    private var parentInfo: String? {
        guard let item = item else { return nil }

        if let artists = item.artists, !artists.isEmpty {
            return artists.first
        } else if let seriesName = item.seriesName ?? item.album {
            return seriesName
        } else if let productionYear = item.productionYear {
            return productionYear.description
        }
        return nil
    }

    private var episodeInfo: String? {
        guard let item = item, item.indexNumber != nil, item.parentIndexNumber != nil else { return nil }

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
