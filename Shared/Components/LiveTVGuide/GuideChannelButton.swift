//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct GuideChannelButton: View {

    let channel: BaseItemDto
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Content(channel: channel)
        }
        .buttonStyle(GuideButtonStyle())
        #if os(tvOS)
            .focusEffectDisabled()
        #endif
    }
}

extension GuideChannelButton {

    private struct Content: View {

        private let layout = LiveTVGuideLayout()
        @Environment(\.isFocused)
        private var isFocused
        @Environment(\.isSelected)
        private var isSelected

        let channel: BaseItemDto

        private var posterSize: CGFloat {
            let height = layout.rowHeight
            guard UIDevice.isTV else { return height }
            return isFocused ? height : height - 8
        }

        private var borderWidth: CGFloat {
            if isFocused {
                5
            } else if isSelected {
                2
            } else {
                0
            }
        }

        var body: some View {
            PosterImage(
                item: channel,
                type: .square,
                contentMode: .fill
            )
            .frame(width: posterSize, height: posterSize)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(.tint, lineWidth: borderWidth)
            }
            .overlay(alignment: .bottomTrailing) {
                if isSelected {
                    Image(systemName: "play.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.white, .tint)
                        .subtleShadow()
                        .padding(4)
                }
            }
            .frame(width: layout.channelColumnWidth, height: layout.rowHeight)
            .animation(.easeOut(duration: 0.1), value: isFocused)
        }
    }
}
