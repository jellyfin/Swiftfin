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
    let isSelected: Bool
    let playsOnSelect: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Content(
                channel: channel,
                isSelected: isSelected,
                playsOnSelect: playsOnSelect
            )
        }
        .buttonStyle(GuideButtonStyle())
        #if os(tvOS)
            .focusEffectDisabled()
        #endif
    }
}

extension GuideChannelButton {

    private struct Content: View {

        @Environment(\.isFocused)
        private var isFocused

        let channel: BaseItemDto
        let isSelected: Bool
        let playsOnSelect: Bool

        private var posterSize: CGFloat {
            let height = GuideLayout.current.rowHeight
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
            .overlay {
                if isFocused, playsOnSelect {
                    ZStack {
                        Color.black
                            .opacity(0.5)

                        Image(systemName: "play.fill")
                            .font(.title3)
                            .foregroundStyle(.white)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(.foreground, lineWidth: borderWidth)
            }
            .overlay(alignment: .bottomTrailing) {
                if isSelected {
                    Image(systemName: "play.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.white, .foreground)
                        .subtleShadow()
                        .padding(4)
                }
            }
            .frame(width: GuideLayout.current.channelColumnWidth, height: GuideLayout.current.rowHeight)
            .animation(.easeOut(duration: 0.1), value: isFocused)
        }
    }
}
