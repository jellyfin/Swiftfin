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

struct GuideChannelButton: View {

    let channel: BaseItemDto
    let width: CGFloat
    let height: CGFloat
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Content(
                channel: channel,
                width: width,
                height: height,
                isSelected: isSelected
            )
        }
        .buttonStyle(GuideButtonStyle())
    }
}

extension GuideChannelButton {

    private struct Content: View {

        @Default(.accentColor)
        private var accentColor

        @Environment(\.isFocused)
        private var isFocused

        let channel: BaseItemDto
        let width: CGFloat
        let height: CGFloat
        let isSelected: Bool

        private var borderWidth: CGFloat {
            if isFocused {
                4
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
            .frame(width: height, height: height)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(accentColor, lineWidth: borderWidth)
            }
            .overlay(alignment: .bottomTrailing) {
                if isSelected {
                    Image(systemName: "play.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.white, accentColor)
                        .padding(4)
                }
            }
            .frame(width: width, height: height)
        }
    }
}
