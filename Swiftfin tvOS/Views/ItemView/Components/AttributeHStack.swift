//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension ItemView {
    struct AttributesHStack: View {
        @ObservedObject
        var viewModel: ItemViewModel

        @StoredValue(.User.itemViewAttributes)
        private var itemViewAttributes

        var body: some View {
            if itemViewAttributes.isNotEmpty {
                HStack(spacing: 25) {
                    ForEach(itemViewAttributes, id: \.self) { attribute in
                        getAttribute(attribute)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                }
                .lineLimit(1)
                .foregroundStyle(Color(UIColor.darkGray))
            }
        }

        @ViewBuilder
        func getAttribute(_ attribute: ItemViewAttribute) -> some View {
            switch attribute {
            case .ratingCritics:
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
            case .ratingCommunity:
                if let communityRating = viewModel.item.communityRating {
                    AttributeBadge(
                        style: .outline,
                        title: Text("\(communityRating, specifier: "%.01f")"),
                        systemName: "star.fill"
                    )
                }
            case .ratingOfficial:
                if let officialRating = viewModel.item.officialRating {
                    AttributeBadge(style: .outline, title: officialRating)
                }
            case .videoQuality:
                if viewModel.selectedMediaSource?.mediaStreams?.has4KVideo == true {
                    AttributeBadge(style: .fill, title: "4K")
                } else if viewModel.selectedMediaSource?.mediaStreams?.hasHDVideo == true {
                    AttributeBadge(style: .fill, title: "HD")
                }
                if viewModel.selectedMediaSource?.mediaStreams?.hasDolbyVision == true {
                    AttributeBadge(style: .fill, title: "DV")
                }
                if viewModel.selectedMediaSource?.mediaStreams?.hasHDRVideo == true {
                    AttributeBadge(style: .fill, title: "HDR")
                }
            case .audioChannels:
                if viewModel.selectedMediaSource?.mediaStreams?.has51AudioChannelLayout == true {
                    AttributeBadge(style: .fill, title: "5.1")
                }
                if viewModel.selectedMediaSource?.mediaStreams?.has71AudioChannelLayout == true {
                    AttributeBadge(style: .fill, title: "7.1")
                }
            case .subtitles:
                if viewModel.selectedMediaSource?.mediaStreams?.hasSubtitles == true {
                    AttributeBadge(style: .outline, title: "CC")
                }
            }
        }
    }
}
