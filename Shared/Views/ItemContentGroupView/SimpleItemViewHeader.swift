//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct SimpleItemViewHeader: ContentGroup {

    let id = "item-view-header"
    let viewModel: Empty = .init()
    let itemViewModel: ItemViewModel

    func body(with viewModel: Empty) -> Body {
        Body(viewModel: itemViewModel)
    }

    struct Body: View {

        @ObservedObject
        var viewModel: ItemViewModel

        @Router
        private var router

        @ViewBuilder
        private func parentButton(_ title: String, id: String) -> some View {
            Button {
                router.route(
                    to: .item(
                        displayTitle: title,
                        id: id
                    )
                )
            } label: {
                HStack(spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)

                    Image(systemName: "chevron.forward")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .fontWeight(.semibold)
            }
            .foregroundStyle(.primary, .secondary)
        }

        @ViewBuilder
        private var titleAndAttributes: some View {
            VStack(alignment: .center, spacing: 5) {

                switch viewModel.item.type {
                case .episode:
                    if let parentID = viewModel.item.seriesID, let parentTitle = viewModel.item.parentTitle {
                        parentButton(parentTitle, id: parentID)
                    }
                case .liveTvProgram:
                    if let channelID = viewModel.item.channelID, let channelName = viewModel.item.channelName {
                        parentButton(channelName, id: channelID)
                    }
                default:
                    EmptyView()
                }

                Text(viewModel.item.displayTitle)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                DotHStack {
                    if let firstGenre = viewModel.item.genres?.first {
                        Text(firstGenre)
                    }

                    if let premiereYear = viewModel.item.premiereDateYear {
                        Text(premiereYear)
                    }

                    if let runtime = viewModel.item.runtime {
                        Text(runtime, format: .hourMinuteAbbreviated)
                    }

                    if let seasonEpisodeLabel = viewModel.item.seasonEpisodeLabel {
                        Text(seasonEpisodeLabel)
                    }
                }
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            }
        }

        private var headerImageDisplayType: PosterDisplayType {
            viewModel.item.preferredPosterDisplayType == .portrait ? .landscape : viewModel.item.preferredPosterDisplayType
        }

        @ViewBuilder
        private var overlay: some View {
            VStack(spacing: 10) {
                PosterImage(
                    item: viewModel.item,
                    type: headerImageDisplayType,
                    contentMode: .fit
                )
                .frame(maxWidth: headerImageDisplayType == .square ? 400 : .infinity)
                .accessibilityIgnoresInvertColors()
                .posterShadow()
                .customEnvironment(for: BaseItemDto.self, value: .init(useParent: false))

                titleAndAttributes

                VStack(alignment: .center, spacing: 10) {
                    if viewModel.item.presentPlayButton {
                        PlayButton(viewModel: viewModel)
                    }

                    ActionButtonHStack(
                        item: viewModel.item,
                        localTrailers: viewModel.localTrailers
                    )
                }
                .frame(maxWidth: 300)

                Divider()

                VStack(alignment: .leading, spacing: 5) {
                    if let tagline = viewModel.item.taglines?.first {
                        Text(tagline)
                            .fontWeight(.bold)
                            .lineLimit(2)
                    }

                    if let overview = viewModel.item.overview {
                        SeeMoreText(overview) {
                            router.route(to: .itemOverview(item: viewModel.item))
                        }
                        .font(.footnote)
                        .lineLimit(3)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                AttributesHStack(
                    item: viewModel.item,
                    mediaSource: nil
                )
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .edgePadding(.bottom)
        }

        var body: some View {
            VStack {
                overlay
                    .edgePadding(.horizontal)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}
