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

    struct iPadOSBody: View {

        @Environment(\.frameForParentView)
        private var frameForParentView

        @ObservedObject
        var viewModel: _ItemViewModel

        @Namespace
        private var namespace

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
            HStack(alignment: .bottom, spacing: EdgeInsets.edgePadding) {
                VStack(alignment: .leading, spacing: 10) {
                    logo

                    ItemView.OverviewView(item: viewModel.item)
                        .overviewLineLimit(3)
                        .taglineLineLimit(2)

                    HStack(alignment: .top) {
                        AttributesHStack(
                            item: viewModel.item,
                            mediaSource: nil
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
                }
                .frame(minWidth: 150)
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
                    .aspectRatio(1.77, contentMode: .fit)
            } content: {
                overlay
                    .edgePadding(.horizontal)
                    .frame(maxWidth: .infinity)
                    .colorScheme(.dark)
            }

//            ZStack {
//                overlay
//                    .edgePadding(.horizontal)
//                    .frame(maxWidth: .infinity)
//                    .colorScheme(.dark)
//            }
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
            .environment(\.frameForParentView, frameForParentView.removingValue(for: .navigationStack))
            .preference(key: _UseOffsetNavigationBarKey.self, value: true)
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
