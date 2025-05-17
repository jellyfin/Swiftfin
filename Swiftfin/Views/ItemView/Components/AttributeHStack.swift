//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI
import WrappingHStack

extension ItemView {

    struct AttributesHStack: View {

        @StoredValue(.User.itemViewAttributes)
        private var itemViewAttributes

        @ObservedObject
        private var viewModel: ItemViewModel

        private let alignment: HorizontalAlignment

        init(
            viewModel: ItemViewModel,
            alignment: HorizontalAlignment = .center
        ) {
            self.viewModel = viewModel
            self.alignment = alignment
        }

        var body: some View {
            let badges = computeBadges()

            if badges.isNotEmpty {
                WrappingHStack(
                    badges,
                    id: \.self,
                    alignment: alignment,
                    spacing: .constant(8),
                    lineSpacing: 8
                ) { badgeItem in
                    badgeItem
                        .fixedSize(horizontal: true, vertical: false)
                }
                .foregroundStyle(Color(UIColor.darkGray))
                .lineLimit(1)
            }
        }

        // MARK: - Compute Badges

        private func computeBadges() -> [AttributeBadge] {
            var badges: [AttributeBadge] = []

            for attribute in itemViewAttributes {

                var badge: AttributeBadge? = nil

                switch attribute {
                case .ratingCritics:
                    if let criticRating = viewModel.item.criticRating {
                        badge = AttributeBadge(
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
                case .ratingCommunity:
                    if let communityRating = viewModel.item.communityRating {
                        badge = AttributeBadge(
                            style: .outline,
                            title: Text("\(communityRating, specifier: "%.01f")"),
                            systemName: "star.fill"
                        )
                    }
                case .ratingOfficial:
                    if let officialRating = viewModel.item.officialRating {
                        badge = AttributeBadge(
                            style: .outline,
                            title: officialRating
                        )
                    }
                case .videoQuality:
                    if let mediaStreams = viewModel.selectedMediaSource?.mediaStreams {
                        // Resolution badge (if available). Only one of 4K or HD is shown.
                        if mediaStreams.has4KVideo {
                            badge = AttributeBadge(
                                style: .fill,
                                title: "4K"
                            )
                        } else if mediaStreams.hasHDVideo {
                            badge = AttributeBadge(
                                style: .fill,
                                title: "HD"
                            )
                        }
                        if mediaStreams.hasDolbyVision {
                            badge = AttributeBadge(
                                style: .fill,
                                title: "DV"
                            )
                        }
                        if mediaStreams.hasHDRVideo {
                            badge = AttributeBadge(
                                style: .fill,
                                title: "HDR"
                            )
                        }
                    }
                case .audioChannels:
                    if let mediaStreams = viewModel.selectedMediaSource?.mediaStreams {
                        if mediaStreams.has51AudioChannelLayout {
                            badge = AttributeBadge(
                                style: .fill,
                                title: "5.1"
                            )
                        }
                        if mediaStreams.has71AudioChannelLayout {
                            badge = AttributeBadge(
                                style: .fill,
                                title: "7.1"
                            )
                        }
                    }
                case .subtitles:
                    if let mediaStreams = viewModel.selectedMediaSource?.mediaStreams,
                       mediaStreams.hasSubtitles
                    {
                        badge = AttributeBadge(
                            style: .outline,
                            title: "CC"
                        )
                    }
                }

                if let badge {
                    badges.append(badge)
                }
            }

            return badges
        }
    }
}
