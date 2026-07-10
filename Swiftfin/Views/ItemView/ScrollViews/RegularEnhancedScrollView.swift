//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Engine
import JellyfinAPI
import SwiftUI

extension ItemView {

    struct RegularEnhancedScrollView: View {

        @ObservedObject
        var provider: ItemContentGroupProvider
        @ObservedObject
        var viewModel: ContentGroupViewModel<ItemContentGroupProvider>

        @StoredValue(.User.itemViewAttributes)
        private var attributes

        @Router
        private var router

        private let headerAspectRatio = 2.0

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

        private func resolveColor(from image: UIImage, binding: Binding<Color>) {
            Task.detached(priority: .utility) {
                guard let color = image.interestingColor() else { return }

                await MainActor.run {
                    binding.wrappedValue = color
                }
            }
        }

        @ViewBuilder
        private var header: some View {
            AlternateLayoutView(alignment: .bottom) {
                Color.clear
                    .aspectRatio(headerAspectRatio, contentMode: .fit)
            } content: {
                overlay
                    .edgePadding(.horizontal)
                    .frame(maxWidth: .infinity)
                    .colorScheme(.dark)
            }
            .backgroundParallaxHeader(
                multiplier: 0.3
            ) {
                StateAdapter(initialValue: Color.secondarySystemFill) { resolvedColor in
                    AlternateLayoutView {
                        Color.clear
                    } content: {
                        ImageView(headerImageSource)
                            .image { (image: UIImage) in
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(1.77, contentMode: .fill)
                                    .onAppear {
                                        resolveColor(from: image, binding: resolvedColor)
                                    }
                            }
                            .clipped()
                            .animation(.linear(duration: 0.1), value: headerImageSource.url?.hashValue)
                    }
                    .aspectRatio(headerAspectRatio, contentMode: .fit)
                    .bottomEdgeGradient(bottomColor: resolvedColor.wrappedValue)
                    .accessibilityHidden(true)
                }
                .id(headerImageSource.url?.hashValue)
            }
            .trackingFrame(
                for: .scrollViewHeader,
                key: ScrollViewHeaderFrameKey.self
            )
        }

        var body: some View {
            BlurredNavigationBarScrollView {
                VStack(alignment: .leading, spacing: EdgeInsets.edgePadding) {
                    header

                    ContentGroupVStack(groups: viewModel.groups)
                }
                .edgePadding(.bottom)
            }
        }
    }
}
