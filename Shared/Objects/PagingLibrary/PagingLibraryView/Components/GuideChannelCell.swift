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

struct GuideChannelCell: View {

    let channel: BaseItemDto
    let width: CGFloat
    let height: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Content(
                channel: channel,
                width: width,
                height: height
            )
        }
        .buttonStyle(GuideButtonStyle())
    }
}

extension GuideChannelCell {

    private struct Content: View {

        @Default(.accentColor)
        private var accentColor

        @Environment(\.isFocused)
        private var isFocused

        let channel: BaseItemDto
        let width: CGFloat
        let height: CGFloat

        var body: some View {
            PosterImage(item: channel, type: .square, contentMode: .fill, maxWidth: 240)
                .frame(width: height - 8, height: height - 8)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(accentColor, lineWidth: isFocused ? 4 : 0)
                }
                .frame(width: width, height: height)
        }
    }
}
