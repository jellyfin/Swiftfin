//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension ItemView {

    struct AttributesHStack: View {

        @ObservedObject
        private var viewModel: ItemViewModel

        private let alignment: HorizontalAlignment
        private let attributes: [ItemViewAttribute]
        private let flowDirection: FlowLayout.Direction

        init(
            attributes: [ItemViewAttribute],
            viewModel: ItemViewModel,
            alignment: HorizontalAlignment = .center,
            flowDirection: FlowLayout.Direction = .up
        ) {
            self.viewModel = viewModel
            self.alignment = alignment
            self.attributes = attributes
            self.flowDirection = flowDirection
        }

        var body: some View {
            if attributes.isNotEmpty {
                FlowLayout(
                    alignment: alignment,
                    direction: flowDirection,
                    spacing: 20
                ) {
                    ForEach(attributes, id: \.self) { attribute in
                        switch attribute {
                        case .ratingCritics: CriticRating()
                        case .ratingCommunity: CommunityRating()
                        case .ratingOfficial: OfficialRating()
                        case .videoQuality: VideoQuality()
                        case .audioChannels: AudioChannels()
                        case .subtitles: Subtitles()
                        }
                    }
                }
                .foregroundStyle(Color(UIColor.darkGray))
                .lineLimit(1)
            }
        }

        @ViewBuilder
        private func CriticRating() -> some View {
            if let criticRating = viewModel.item.criticRating {
                AttributeBadge(
                    style: .outline,
                    title: Text("\(criticRating, specifier: "%.0f")")
                ) {
                    if criticRating >= 60 {
                        Image(.tomatoFresh)
                            .symbolRenderingMode(.hierarchical)
                    } else {
                        Image(.tomatoRotten)
                    }
                }
            }
        }

        @ViewBuilder
        private func CommunityRating() -> some View {
            if let communityRating = viewModel.item.communityRating {
                AttributeBadge(
                    style: .outline,
                    title: Text("\(communityRating, specifier: "%.01f")"),
                    systemName: "star.fill"
                )
            }
        }

        @ViewBuilder
        private func OfficialRating() -> some View {
            if let officialRating = viewModel.item.officialRating {
                AttributeBadge(
                    style: .outline,
                    title: officialRating
                )
            }
        }

        @ViewBuilder
        private func VideoQuality() -> some View {
            if let mediaStreams = viewModel.selectedMediaSource?.mediaStreams {
                if mediaStreams.has4KVideo {
                    AttributeBadge(
                        style: .fill,
                        title: "4K"
                    )
                } else if mediaStreams.hasHDVideo {
                    AttributeBadge(
                        style: .fill,
                        title: "HD"
                    )
                }
                if mediaStreams.hasDolbyVision {
                    AttributeBadge(
                        style: .fill,
                        title: "DV"
                    )
                }
                if mediaStreams.hasHDRVideo {
                    AttributeBadge(
                        style: .fill,
                        title: "HDR"
                    )
                }
            }
        }

        @ViewBuilder
        private func AudioChannels() -> some View {
            if let mediaStreams = viewModel.selectedMediaSource?.mediaStreams {
                if mediaStreams.has51AudioChannelLayout {
                    AttributeBadge(
                        style: .fill,
                        title: "5.1"
                    )
                }
                if mediaStreams.has71AudioChannelLayout {
                    AttributeBadge(
                        style: .fill,
                        title: "7.1"
                    )
                }
            }
        }

        @ViewBuilder
        private func Subtitles() -> some View {
            if let mediaStreams = viewModel.selectedMediaSource?.mediaStreams,
               mediaStreams.hasSubtitles
            {
                AttributeBadge(
                    style: .outline,
                    title: "CC"
                )
            }
        }
    }
}
