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
            HStack(spacing: 25) {
                ForEach(itemViewAttributes, id: \.self) { attribute in
                    getAttribute(attribute)
                }
            }
            .foregroundStyle(Color(UIColor.darkGray))
        }

        @ViewBuilder
        func getAttribute(_ attribute: ItemViewAttribute) -> some View {
            switch attribute {
            case .ratingCritics:
                if let criticRating = viewModel.item.criticRating {
                    HStack(spacing: 2) {
                        Group {
                            if criticRating >= 60 {
                                Image(.tomatoFresh)
                                    .symbolRenderingMode(.hierarchical)
                            } else {
                                Image(.tomatoRotten)
                            }
                        }
                        .font(.caption2)

                        Text("\(criticRating, specifier: "%.0f")")
                    }
                    .asAttributeStyle(.outline)
                }
            case .ratingCommunity:
                if let communityRating = viewModel.item.communityRating {
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .font(.caption2)

                        Text("\(communityRating, specifier: "%.1f")")
                    }
                    .asAttributeStyle(.outline)
                }
            case .ratingOfficial:
                if let officialRating = viewModel.item.officialRating {
                    Text(officialRating)
                        .asAttributeStyle(.outline)
                }
            case .videoQuality:
                if viewModel.selectedMediaSource?.mediaStreams?.hasHDVideo == true {
                    Text("HD")
                        .asAttributeStyle(.fill)
                }
                if viewModel.selectedMediaSource?.mediaStreams?.has4KVideo == true {
                    Text("4K")
                        .asAttributeStyle(.fill)
                }
            case .audioChannels:
                if viewModel.selectedMediaSource?.mediaStreams?.has51AudioChannelLayout == true {
                    Text("5.1")
                        .asAttributeStyle(.fill)
                }
                if viewModel.selectedMediaSource?.mediaStreams?.has71AudioChannelLayout == true {
                    Text("7.1")
                        .asAttributeStyle(.fill)
                }
            case .subtitles:
                if viewModel.selectedMediaSource?.mediaStreams?.hasSubtitles == true {
                    Text("CC")
                        .asAttributeStyle(.outline)
                }
            }
        }
    }
}
