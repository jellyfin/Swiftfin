//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import Engine
import JellyfinAPI
import SwiftUI

extension ItemView {

    struct CompactEnhancedScrollView: View {

        @ObservedObject
        var provider: ItemContentGroupProvider
        @ObservedObject
        var viewModel: ContentGroupViewModel<ItemContentGroupProvider>

        @StoredValue(.User.itemViewAttributes)
        private var attributes

        @Router
        private var router

        private let headerAspectRatio = 1.6

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
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
            }
            .aspectRatio(contentMode: .fit)
            .frame(height: 70, alignment: .bottom)
            .accessibilityLabel(provider.item.displayTitle)
            .accessibilityRemoveTraits(.isImage)
        }

        @ViewBuilder
        private var overlay: some View {
            VStack(alignment: .center, spacing: 10) {
                AlternateLayoutView(alignment: .bottom) {
                    Color.clear
                        .aspectRatio(headerAspectRatio, contentMode: .fit)
                } content: {
                    logo
                }
                .zIndex(10)

                VStack(alignment: .center, spacing: 10) {
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

                    VStack(alignment: .center, spacing: 5) {
                        if provider.item.presentPlayButton {
                            PlayButton(provider: provider)
                                .frame(height: 50)
                        }

                        ItemView.ActionButtonHStack(provider: provider)
                            .frame(height: 50)
                    }
                    .frame(maxWidth: 300)

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
                .edgePadding(.bottom)
                .background(
                    alignment: .bottom,
                    extendedBy: .init(
                        vertical: 25,
                        horizontal: EdgeInsets.edgePadding
                    )
                ) {
                    Rectangle()
                        .fill(Material.ultraThin)
                        .mask {
                            EasedGradient(
                                stops: [
                                    .init(color: .clear, location: 0),
                                    .init(color: .white, location: 0.2),
                                ],
                                startPoint: .top,
                                endPoint: .bottom,
                                curve: .easeOut
                            )
                        }
                }
                .zIndex(9)
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
            overlay
                .edgePadding(.horizontal)
                .frame(maxWidth: .infinity)
                .colorScheme(.dark)
                .backgroundParallaxHeader(multiplier: 0.3) {
                    StateAdapter(initialValue: Color.secondarySystemFill) { resolvedColor in
                        MirrorExtensionView(edges: .top) {
                            AlternateLayoutView {
                                Color.clear
                            } content: {
                                ImageView(provider.item.imageSource(
                                    .backdrop,
                                    environment: ImageSourceOptions(maxWidth: 1320)
                                ))
                                .image { (image: UIImage) in
                                    Image(uiImage: image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .onAppear {
                                            resolveColor(from: image, binding: resolvedColor)
                                        }
                                }
                            }
                            .aspectRatio(headerAspectRatio, contentMode: .fit)
                            .accessibilityHidden(true)
                        }
                        .bottomEdgeGradient(bottomColor: resolvedColor.wrappedValue)
                    }
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
