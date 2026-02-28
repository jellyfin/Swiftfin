//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension EnhancedItemViewHeader {

    struct RegularBody: View {

        @Environment(\.frameForParentView)
        private var frameForParentView

        @ObservedObject
        var viewModel: ItemViewModel

        @Router
        private var router

        @ViewBuilder
        private var logo: some View {
            ImageView(viewModel.item.imageURL(.logo, maxHeight: 70))
                .placeholder { _ in
                    EmptyView()
                }
                .failure {
                    Text(viewModel.item.displayTitle)
                        .fixedSize(horizontal: false, vertical: true)
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(.primary)
                }
                .aspectRatio(contentMode: .fit)
                .frame(height: 70, alignment: .bottom)
        }

        @ViewBuilder
        private var overlay: some View {
            HStack(alignment: .bottom, spacing: EdgeInsets.edgePadding) {
                VStack(alignment: .leading, spacing: 10) {
                    logo

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

                    HStack(alignment: .top) {
                        AttributesHStack(
                            item: viewModel.item,
                            mediaSource: viewModel.selectedMediaSource
                        )

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
                        }
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)

                VStack(alignment: .center, spacing: 10) {
                    if viewModel.item.presentPlayButton {
                        PlayButton(viewModel: viewModel)
                    }

                    ActionButtonHStack(
                        item: viewModel.item,
                        localTrailers: viewModel.localTrailers
                    )
                }
                #if os(tvOS)
                .frame(width: 450)
                #else
                .frame(maxWidth: 300)
                #endif
            }
            .edgePadding(.bottom)
            .background(
                alignment: .bottom,
                extendedBy: .init(horizontal: EdgeInsets.edgePadding)
            ) {
                Rectangle()
                    .fill(Material.ultraThin)
                    .maskLinearGradient {
                        (location: 0, opacity: 0)
                        (location: 0.5, opacity: 1)
                    }
            }
        }

        var body: some View {
            AlternateLayoutView(alignment: .bottom) {
                Color.clear
                    .aspectRatio(2, contentMode: .fit)
            } content: {
                overlay
                    .edgePadding(.horizontal)
                    .frame(maxWidth: .infinity)
                    .colorScheme(.dark)
            }
            .backgroundParallaxHeader(
                multiplier: 0.3
            ) {
                AlternateLayoutView {
                    Color.clear
                        .aspectRatio(2, contentMode: .fit)
                } content: {
                    ImageView(
                        viewModel.item.landscapeImageSources(maxWidth: 1320, environment: .init(useParent: false))
                    )
                    .aspectRatio(contentMode: .fit)
                }
            }
            .scrollViewHeaderOffsetOpacity()
            .trackingFrame(
                in: .local,
                for: .scrollViewHeader,
                key: ScrollViewHeaderFrameKey.self
            )
            .environment(\.frameForParentView, frameForParentView.removingValue(for: .navigationStack))
            .preference(key: ContentGroupCustomizationKey.self, value: .useOffsetNavigationBar)
            .preference(key: MenuContentKey.self) {
                //                if viewModel.userSession.user.permissions.items.canEditMetadata(item: viewModel.item) {
                #if os(iOS)
                MenuContentGroup(id: "test") {
                    Button(L10n.edit, systemImage: "pencil") {
                        router.route(to: .editItem(viewModel.item))
                        //                            router.route(to: .settings)
                    }
                }
                #endif
                //                }
            }
        }
    }
}

import Combine
import Factory
import JellyfinAPI
