//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension ChannelLibraryView {

    struct CompactChannelView: View {

        let channel: BaseItemDto
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                VStack(alignment: .leading) {
                    PosterImage(
                        item: channel,
                        type: .square
                    )

                    Text(channel.displayTitle)
                        .font(.footnote.weight(.regular))
                        .foregroundColor(.primary)
                        .lineLimit(1, reservesSpace: true)
                        .font(.footnote.weight(.regular))
                }
            }
            .buttonStyle(.plain)
        }
    }
}
