//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension EnhancedItemViewHeader {

    struct CompactBody: View {

        @Namespace
        private var namespace

        @ObservedObject
        var viewModel: _ItemViewModel

        @Router
        private var router

        @ViewBuilder
        private var logo: some View {
            ImageView(viewModel.item.imageURL(.logo, maxHeight: 70))
                .placeholder { _ in
                    EmptyView()
                }
                .failure {
                    MaxHeightText(viewModel.item.displayTitle)
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.primary)
                }
                .aspectRatio(contentMode: .fit)
                .frame(height: 70, alignment: .bottom)
        }

        @ViewBuilder
        private var overlay: some View {
            VStack(alignment: .center, spacing: 10) {
                AlternateLayoutView(alignment: .bottom) {
                    Color.clear
                        .aspectRatio(1.77, contentMode: .fill)
                } content: {
                    logo
                        .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: .infinity)
                .zIndex(10)

                VStack(alignment: .center, spacing: 10) {
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

                    VStack(alignment: .center, spacing: 5) {
                        if viewModel.item.presentPlayButton {
                            PlayButton(viewModel: viewModel)
                        }

                        ActionButtonHStack(viewModel: viewModel)
                    }
                    .frame(maxWidth: 300)

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
                        mediaSource: viewModel.selectedMediaSource
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .edgePadding(.bottom)
                .background(
                    alignment: .bottom,
                    extendedBy: .init(vertical: 25, horizontal: EdgeInsets.edgePadding)
                ) {
                    Rectangle()
                        .fill(Material.ultraThin)
                        .maskLinearGradient {
                            (location: 0, opacity: 0)
                            (location: 0.1, opacity: 0.7)
                            (location: 0.2, opacity: 1)
                        }
                }
                .zIndex(9)
            }
        }

        var body: some View {
            VStack {
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
                } content: {
                    ImageView(
                        viewModel.item.landscapeImageSources(maxWidth: 1320, environment: .init(useParent: false))
                    )
                }
                .aspectRatio(1.77, contentMode: .fit)
            }
            .scrollViewHeaderOffsetOpacity()
            .trackingFrame(for: .scrollViewHeader, key: ScrollViewHeaderFrameKey.self)
            .preference(key: _ContentGroupCustomizationKey.self, value: .useOffsetNavigationBar)
            .preference(key: MenuContentKey.self) {
                //                if viewModel.userSession.user.permissions.items.canEditMetadata(item: viewModel.item) {
                #if os(iOS)
                MenuContentGroup(id: "test") {
                    Button(L10n.edit, systemImage: "pencil") {
                        router.route(to: .editItem(viewModel.item))
                    }
                }
                #endif
                //                }
            }
        }
    }
}
