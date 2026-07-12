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

    struct HeaderContentGroup: ContentGroup {

        let id: String = "itemView-header"
        let provider: ItemContentGroupProvider

        func body(with viewModel: Empty) -> Body {
            Body(provider: provider)
        }

        struct Body: View {

            @FocusState
            private var isPlayButtonFocused: Bool

            @ObservedObject
            var provider: ItemContentGroupProvider

            @Router
            private var router

            @StoredValue(.User.itemViewAttributes)
            private var attributes

            private var canFocusPlayButton: Bool {
                provider.item.presentPlayButton && provider.selectedMediaSource != nil
            }

            @ViewBuilder
            private var logo: some View {
                ImageView(
                    provider.item.imageSource(
                        .logo,
                        environment: ImageSourceOptions(maxHeight: 100)
                    )
                )
                .image { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 100)
                }
                .placeholder { _ in
                    EmptyView()
                }
                .failure {
                    Text(provider.item.displayTitle)
                        .fixedSize(horizontal: false, vertical: true)
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(.primary)
                }
                .accessibilityLabel(provider.item.displayTitle)
                .accessibilityRemoveTraits(.isImage)
            }

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
                        insets: .init(vertical: 5, horizontal: 10),
                        isIconTrailing: true
                    )
                )
            }

            @ViewBuilder
            private var overlay: some View {
                HStack(alignment: .bottom, spacing: EdgeInsets.edgePadding) {
                    VStack(alignment: .center, spacing: 5) {
                        logo

                        if provider.item.type == .person || provider.item.type == .musicArtist {
                            ImageView(provider.item.imageSource(.primary, environment: ImageSourceOptions(maxWidth: 200)))
                                .failure {
                                    SystemImageContentView(systemName: provider.item.systemImage)
                                }
                                .posterStyle(.portrait, contentMode: .fit)
                                .frame(width: 200)
                                .accessibilityIgnoresInvertColors()
                        }

                        if provider.item.presentPlayButton {
                            PlayButton(
                                provider: provider,
                                playButtonFocus: $isPlayButtonFocused
                            )
                        }

                        ItemView.ActionButtonHStack(provider: provider)
                    }
                    .frame(width: 450)

                    VStack(alignment: .leading, spacing: 10) {

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

                        VStack(alignment: .leading, spacing: 5) {
                            if let firstTagline = provider.item.taglines?.first {
                                Text(firstTagline)
                                    .fontWeight(.bold)
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(2)
                            }

                            if let itemOverview = provider.item.overview {
                                Text(itemOverview)
                                    .font(.footnote)
                                    .lineLimit(3)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        HStack(alignment: .top) {
                            ItemView.AttributesHStack(
                                attributes: attributes,
                                item: provider.item,
                                selectedMediaSource: provider.selectedMediaSource,
                                alignment: .leading
                            )

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
                    .frame(maxWidth: .infinity)
                }
                .edgePadding(.bottom)
                .focusSection()
                .if(canFocusPlayButton) { view in
                    view
                        .backport
                        .defaultFocus(
                            $isPlayButtonFocused,
                            true,
                            priority: .userInitiated
                        )
                }
            }

            var body: some View {
                CinematicContentGroupContainer {
                    overlay
                        .edgePadding(.horizontal)
                        .frame(maxWidth: .infinity)
                        .colorScheme(.dark)
                }
                .preference(
                    key: ContentGroupCustomizationKey.self,
                    value: .ignoreSafeAreaTop
                )
            }
        }
    }
}
