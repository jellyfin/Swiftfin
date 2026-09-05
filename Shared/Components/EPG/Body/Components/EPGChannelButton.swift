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

    let channel: BaseItemDto
    let action: () -> Void

    private let layout = EPGLayout()

    private var posterSize: CGFloat {
        min(
            UIDevice.isTV && !isFocused ? layout.rowHeight - 8 : layout.rowHeight,
            layout.channelColumnWidth
        )
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

    private var hasPrimaryImage: Bool {
        channel.imageTags?[ImageType.primary.rawValue] != nil
    }

    @ViewBuilder
    private var channelContent: some View {
        if hasPrimaryImage {
            PosterImage(
                item: channel,
                type: .square,
                contentMode: .fill
            )
        } else {
            ZStack {
                Color.secondarySystemFill

                VStack(spacing: 2) {
                    if let channelNumber = channel.channelNumber, channelNumber.isNotEmpty {
                        Text(channelNumber)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }

                    Text(channel.displayTitle)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.7)
                }
                .foregroundStyle(.primary)
                .padding(6)
            }
        }
    }

    var body: some View {
        Button(action: action) {
            channelContent
                .frame(width: posterSize, height: posterSize)
                .clipped()
                .overlay {
                    Rectangle()
                        .strokeBorder(.tint, lineWidth: borderWidth)
                }
                .frame(width: layout.channelColumnWidth, height: layout.rowHeight)
                .animation(.easeOut(duration: 0.1), value: isFocused)
        }
        .buttonStyle(EPGButtonStyle())
        .focused($isFocused)
    }
}
