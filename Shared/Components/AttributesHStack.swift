//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct AttributesHStack: View {

    private let alignment: HorizontalAlignment
    private let flowDirection: FlowLayout.Direction
    private let item: BaseItemDto
    private let mediaSource: MediaSourceInfo?

    init(
        item: BaseItemDto,
        mediaSource: MediaSourceInfo?,
        alignment: HorizontalAlignment = .center,
        flowDirection: FlowLayout.Direction = .up
    ) {
        self.alignment = alignment
        self.flowDirection = flowDirection
        self.item = item
        self.mediaSource = mediaSource
    }

    var body: some View {
        FlowLayout(
            alignment: alignment,
            direction: flowDirection,
            spacing: UIDevice.isTV ? 20 : 8
        ) {
            CriticRating()
            CommunityRating()
            OfficialRating()
            VideoQuality()
            AudioChannels()
            Subtitles()
        }
        .foregroundStyle(.secondary)
        .lineLimit(1)
    }

    @ViewBuilder
    private func CriticRating() -> some View {
        if let criticRating = item.criticRating {
            AttributeBadge(style: .outline) {
                Label {
                    Text("\(criticRating, specifier: "%.0f")")
                } icon: {
                    if criticRating >= 60 {
                        Image(.tomatoFresh)
                            .symbolRenderingMode(.hierarchical)
                    } else {
                        Image(.tomatoRotten)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func CommunityRating() -> some View {
        if let communityRating = item.communityRating {
            AttributeBadge(style: .outline) {
                Label {
                    Text("\(communityRating, specifier: "%.01f")")
                } icon: {
                    Image(systemName: "star.fill")
                }
            }
        }
    }

    @ViewBuilder
    private func OfficialRating() -> some View {
        if let officialRating = item.officialRating {
            AttributeBadge(style: .outline) {
                Text(officialRating)
            }
        }
    }

    @ViewBuilder
    private func VideoQuality() -> some View {
        if let mediaStreams = mediaSource?.mediaStreams {
            if mediaStreams.has4KVideo {
                AttributeBadge(style: .fill) {
                    Text("4K")
                }
            } else if mediaStreams.hasHDVideo {
                AttributeBadge(style: .fill) {
                    Text("HD")
                }
            }
            if mediaStreams.hasDolbyVision {
                AttributeBadge(style: .fill) {
                    Text("DV")
                }
            }
            if mediaStreams.hasHDRVideo {
                AttributeBadge(style: .fill) {
                    Text("HDR")
                }
            }
        }
    }

    @ViewBuilder
    private func AudioChannels() -> some View {
        if let mediaStreams = mediaSource?.mediaStreams {
            if mediaStreams.has51AudioChannelLayout {
                AttributeBadge(style: .fill) {
                    Text("5.1")
                }
            }
            if mediaStreams.has71AudioChannelLayout {
                AttributeBadge(style: .fill) {
                    Text("7.1")
                }
            }
        }
    }

    @ViewBuilder
    private func Subtitles() -> some View {
        if let mediaStreams = mediaSource?.mediaStreams,
           mediaStreams.hasSubtitles
        {
            AttributeBadge(style: .outline) {
                Text("CC")
            }
        }
    }
}
