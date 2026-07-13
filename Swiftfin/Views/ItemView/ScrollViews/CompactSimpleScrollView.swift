//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension ItemView {

    struct CompactSimpleScrollView: View {

        @ObservedObject
        var provider: ItemContentGroupProvider
        @ObservedObject
        var viewModel: ContentGroupViewModel<ItemContentGroupProvider>

        @Router
        private var router

        @StoredValue(.User.itemViewAttributes)
        private var attributes

        @ViewBuilder
        private func parentButton(_ title: String, id: String) -> some View {
            Button {
                router.route(to: .item(id: id))
            } label: {
                Label {
                    Text(title)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                } icon: {
                    Image(systemName: "chevron.forward")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .font(.callout)
                .fontWeight(.semibold)
            }
            .foregroundStyle(.primary, .secondary)
            .labelStyle(
                CapsuleLabelStyle(
                    isIconTrailing: true
                )
            )
        }

        @ViewBuilder
        private var titleAndAttributes: some View {
            VStack(alignment: .center, spacing: 5) {
                switch provider.item.type {
                case .episode:
                    if let parentID = provider.item.seriesID, let parentTitle = provider.item.parentTitle {
                        parentButton(parentTitle, id: parentID)
                    }
                case .liveTvProgram:
                    if let channelID = provider.item.channelID, let channelName = provider.item.channelName {
                        parentButton(channelName, id: channelID)
                    }
                default:
                    EmptyView()
                }

                Text(provider.item.displayTitle)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                DotHStack {
                    if let firstGenre = provider.item.genres?.first {
                        Text(firstGenre)
                    }

                    if let premiereYear = provider.item.premiereDateYear {
                        Text(premiereYear)
                    }

                    if let runtime = provider.item.runtime {
                        Text(runtime, format: .hourMinuteAbbreviated)
                    }

                    if let seasonEpisodeLabel = provider.item.seasonEpisodeLabel {
                        Text(seasonEpisodeLabel)
                    }
                }
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            }
        }

        private var headerImageDisplayType: PosterDisplayType {
            provider.item.preferredPosterDisplayType == .portrait ? .landscape : provider.item.preferredPosterDisplayType
        }

        @ViewBuilder
        private var header: some View {
            VStack(spacing: 10) {
                PosterImage(
                    item: provider.item,
                    type: headerImageDisplayType,
                    contentMode: .fit
                )
                .posterEnvironment(BaseItemDto.Environment(useParent: false))
                .frame(maxWidth: headerImageDisplayType == .square ? 400 : .infinity)
                .accessibilityIgnoresInvertColors()
                .posterShadow()

                titleAndAttributes

                VStack(alignment: .center, spacing: 5) {
                    if provider.item.presentPlayButton {
                        PlayButton(provider: provider)
                            .frame(height: 50)
                    }

                    ItemView.ActionButtonHStack(provider: provider)
                        .frame(height: 50)
                }
                .frame(maxWidth: 300)

                Divider()

                VStack(alignment: .leading, spacing: 5) {
                    if let firstTagline = provider.item.taglines?.first {
                        Text(firstTagline)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                    }

                    if let itemOverview = provider.item.overview {
                        Button {
                            router.route(to: .itemOverview(item: provider.item))
                        } label: {
                            SeeMoreText(itemOverview)
                                .font(.footnote)
                                .lineLimit(3)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                ItemView.AttributesHStack(
                    attributes: attributes,
                    item: provider.item,
                    selectedMediaSource: provider.selectedMediaSource,
                    alignment: .leading
                )
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .edgePadding()
            .frame(maxWidth: .infinity)
        }

        var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: EdgeInsets.edgePadding) {
                    header

                    ContentGroupVStack(groups: viewModel.groups)
                }
                .edgePadding(.bottom)
            }
            .ignoresSafeArea(edges: .horizontal)
            .scrollIndicators(.hidden)
        }
    }
}
