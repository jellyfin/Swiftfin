//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

extension ItemView {

    struct CompactEnhancedHeaderContentGroup: ContentGroup {

        let id: String = "itemView-header"
        let provider: ItemContentGroupProvider

        func body(with viewModel: Empty) -> Body {
            Body(provider: provider)
        }

        struct Body: View {

            @ObservedObject
            var provider: ItemContentGroupProvider

            @StoredValue(.User.itemViewAttributes)
            private var attributes

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
                        MetadataHStack(item: provider.item)

                        VStack(alignment: .center, spacing: 5) {
                            if provider.item.presentPlayButton || provider.item.canShuffle {
                                PlayButton(provider: provider)
                            }

                            ItemView.ActionButtonHStack(provider: provider)
                        }
                        .frame(maxWidth: 300)

                        ItemView.Description(item: provider.item)

                        ItemView.AttributesHStack(
                            attributes: attributes,
                            item: provider.item,
                            selectedMediaSource: provider.selectedMediaSource,
                            alignment: .leading
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundStyle(.secondary)
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
                            .mask(gradient: .eased(.easeOut)) {
                                (location: 0, opacity: 0)
                                (location: 0.2, opacity: 1)
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

            var body: some View {
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
            }
        }
    }
}
