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

    struct RegularEnhancedScrollView<Content: View>: ScrollContainerView {

        @Environment(\.frameForParentView)
        private var frameForParentView

        @StoredValue(.User.itemViewAttributes)
        private var attributes

        @ObservedObject
        private var provider: ItemContentGroupProvider

        @State
        private var carriedHeaderFrame: CGRect = .zero

        @State
        private var resolvedBottomColor: Color?

        private let content: Content

        init(
            provider: ItemContentGroupProvider,
            content: @escaping () -> Content
        ) {
            self.provider = provider
            self.content = content()
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

        private var imageType: ImageType {
            switch headerImageItem.type {
            case .episode, .musicVideo, .video:
                .primary
            default:
                .backdrop
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
                    }

                    ItemView.ActionButtonHStack(provider: provider)
                }
                .frame(width: 450)
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
                multiplier: 0.3,
                backgroundColor: headerBottomColor
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
        }

        private var headerMaxY: CGFloat? {
            carriedHeaderFrame == .zero ? nil : carriedHeaderFrame.maxY
        }

        var body: some View {
            OffsetNavigationBar(headerMaxY: headerMaxY) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 40) {
                        header

                        content
                            .edgePadding(.bottom)
                    }
                    .onPreferenceChange(ScrollViewHeaderFrameKey.self) { value in
                        carriedHeaderFrame = value.frame
                    }
                }
                .ignoresSafeArea(edges: .horizontal)
                .scrollIndicators(.hidden)
            }
            .trackingFrame(for: .scrollView)
        }
    }
}
