//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct EPGChannelButton: View {

    @Environment(\.isSelected)
    private var isSelected

    @FocusState
    private var isFocused: Bool

    private let layout = EPGLayout()

    let channel: BaseItemDto
    let action: () -> Void

    private var posterSize: CGFloat {
        UIDevice.isTV && !isFocused ? layout.rowHeight - 8 : layout.rowHeight
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
        Button(action: action) {
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
        .buttonStyle(EPGButtonStyle())
        .focused($isFocused)
    }
}
