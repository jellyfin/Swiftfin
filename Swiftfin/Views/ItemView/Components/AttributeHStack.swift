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
        @ObservedObject
        var viewModel: ItemViewModel

        @StoredValue(.User.itemViewAttributes)
        private var itemViewAttributes

        // MARK: - Body

        var body: some View {
            let badges = computeBadges()
            if !badges.isEmpty {
                WrappingHStack(badges, id: \.self, alignment: .center, spacing: .constant(8), lineSpacing: 8) { badgeItem in
                    badgeItem
                        .fixedSize(horizontal: true, vertical: false)
                }
                .foregroundStyle(Color(UIColor.darkGray))
                .lineLimit(1)
                .frame(maxWidth: 300)
            }
        }

        // MARK: - Compute Badges

        private func computeBadges() -> [AnyView] {
            var badges: [AnyView] = []
            var processedGroups = Set<ItemViewAttribute>()

            for attribute in itemViewAttributes {

                if processedGroups.contains(attribute) { continue }
                processedGroups.insert(attribute)

                switch attribute {
                case .ratingCritics:
                    if let criticRating = viewModel.item.criticRating {
                        let badge = AnyView(
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
                        )
                        badges.append(badge)
                    }
                case .ratingCommunity:
                    if let communityRating = viewModel.item.communityRating {
                        let badge = AnyView(
                            AttributeBadge(
                                style: .outline,
                                title: Text("\(communityRating, specifier: "%.01f")"),
                                systemName: "star.fill"
                            )
                        )
                        badges.append(badge)
                    }
                case .ratingOfficial:
                    if let officialRating = viewModel.item.officialRating {
                        let badge = AnyView(
                            AttributeBadge(
                                style: .outline,
                                title: officialRating
                            )
                        )
                        badges.append(badge)
                    }
                case .videoQuality:
                    if let mediaStreams = viewModel.selectedMediaSource?.mediaStreams {
                        // Resolution badge (if available). Only one of 4K or HD is shown.
                        if mediaStreams.has4KVideo {
                            let badge = AnyView(
                                AttributeBadge(
                                    style: .fill,
                                    title: "4K"
                                )
                            )
                            badges.append(badge)
                        } else if mediaStreams.hasHDVideo {
                            let badge = AnyView(
                                AttributeBadge(
                                    style: .fill,
                                    title: "HD"
                                )
                            )
                            badges.append(badge)
                        }
                        if mediaStreams.hasDolbyVision {
                            let badge = AnyView(
                                AttributeBadge(
                                    style: .fill,
                                    title: "DV"
                                )
                            )
                            badges.append(badge)
                        }
                        if mediaStreams.hasHDRVideo {
                            let badge = AnyView(
                                AttributeBadge(
                                    style: .fill,
                                    title: "HDR"
                                )
                            )
                            badges.append(badge)
                        }
                    }
                case .audioChannels:
                    if let mediaStreams = viewModel.selectedMediaSource?.mediaStreams {
                        if mediaStreams.has51AudioChannelLayout {
                            let badge = AnyView(
                                AttributeBadge(
                                    style: .fill,
                                    title: "5.1"
                                )
                            )
                            badges.append(badge)
                        }
                        if mediaStreams.has71AudioChannelLayout {
                            let badge = AnyView(
                                AttributeBadge(
                                    style: .fill,
                                    title: "7.1"
                                )
                            )
                            badges.append(badge)
                        }
                    }
                case .subtitles:
                    if let mediaStreams = viewModel.selectedMediaSource?.mediaStreams,
                       mediaStreams.hasSubtitles
                    {
                        let badge = AnyView(
                            AttributeBadge(
                                style: .outline,
                                title: "CC"
                            )
                        )
                        badges.append(badge)
                    }
                }
            }
            return badges
        }
    }
}
