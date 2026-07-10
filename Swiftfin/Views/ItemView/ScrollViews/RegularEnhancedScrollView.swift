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

    struct RegularEnhancedScrollView: View {

        @Environment(\.frameForParentView)
        private var frameForParentView

        @ObservedObject
        var provider: ItemContentGroupProvider
        @ObservedObject
        var viewModel: ContentGroupViewModel<ItemContentGroupProvider>

        @State
        private var resolvedBottomColor: Color?

        @StoredValue(.User.itemViewAttributes)
        private var attributes

        private var imageType: ImageType {
            switch provider.item.type {
            case .episode, .musicVideo, .video:
                .primary
            default:
                .backdrop
            }
        }

        private var headerImageItem: BaseItemDto {
            if provider.item.type == .person || provider.item.type == .musicArtist,
               let randomItem = provider.randomBackdropItem
            {
                randomItem
            } else {
                provider.item
            }
        }

        private var headerImageSource: ImageSource {
            headerImageItem.imageSource(
                imageType,
                environment: ImageSourceOptions(maxWidth: 1920)
            )
        }

        private var headerBottomColor: Color {
            resolvedBottomColor ?? Color.secondarySystemFill
        }

        @ViewBuilder
        private var logo: some View {
            ImageView(
                provider.item.imageSource(
                    .logo,
                    environment: ImageSourceOptions(maxHeight: 70)
                )
            )
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
            .aspectRatio(contentMode: .fit)
            .frame(height: 70, alignment: .bottom)
        }

        @ViewBuilder
        private var overlay: some View {
            HStack(alignment: .bottom, spacing: EdgeInsets.edgePadding) {
                VStack(alignment: .leading, spacing: 10) {
                    logo

                    ItemView.OverviewView(item: provider.item)
                        .overviewLineLimit(3)
                        .taglineLineLimit(2)
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
                        }
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)

                VStack(alignment: .center, spacing: 5) {
                    if provider.item.presentPlayButton {
                        ItemView.PlayButton(provider: provider)
                            .frame(height: 50)
                    }

                    ItemView.ActionButtonHStack(provider: provider)
                        .frame(height: 50)
                }
                .frame(maxWidth: 300)
            }
            .edgePadding(.bottom)
            .background(
                alignment: .bottom,
                extendedBy: .init(horizontal: EdgeInsets.edgePadding)
            ) {
                Rectangle()
                    .fill(Material.ultraThin)
                    .mask {
                        EasedGradient(
                            stops: [
                                .init(color: .clear, location: 0),
                                .init(color: .white, location: 0.5),
                                .init(color: .white, location: 1),
                            ],
                            startPoint: .top,
                            endPoint: .bottom,
                            curve: .smootherstep
                        )
                    }
            }
        }

        @ViewBuilder
        private var header: some View {
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
                    ImageView(headerImageSource)
//                        .resolvedColor($resolvedBottomColor)
                            .image { image in
                                image
                                    .aspectRatio(1.77, contentMode: .fill)
                            }
                            .clipped()
                            .id(headerImageSource.url?.hashValue)
                            .animation(.linear(duration: 0.1), value: headerImageSource.url?.hashValue)
                }
                .bottomEdgeGradient(bottomColor: headerBottomColor)
            }
            .trackingFrame(
                in: .local,
                for: .scrollViewHeader,
                key: ScrollViewHeaderFrameKey.self
            )
            .environment(
                \.frameForParentView,
                frameForParentView.removingValue(for: .navigationStack)
            )
            .onChange(of: headerImageSource.url) { _ in
                resolvedBottomColor = nil
            }
        }

        var body: some View {
            BlurredNavigationBarScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header

                    ContentGroupVStack(groups: viewModel.groups)
                }
                .edgePadding(.bottom)
            }
        }
    }
}
