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

        let id: String = ItemView.Component.header
        let provider: ItemContentGroupProvider

        func body(with viewModel: Empty) -> Body {
            Body(provider: provider)
        }

        struct Body: View {

            @AdaptiveLayout
            private var viewLayout

            @Environment(\.frameForParentView)
            private var frameForParentView
            @Environment(\.layoutDirection)
            private var layoutDirection

            @ObservedObject
            var provider: ItemContentGroupProvider

            @StoredValue(.User.itemViewAttributes)
            private var attributes

            private let headerAspectRatio = 1.6

            private var artworkLayout: ViewLayout {
                guard let navigation = frameForParentView[.navigationStack], navigation.frame.width > 0 else {
                    return viewLayout
                }

                return viewLayout.resolving(size: navigation.sizeIncludingSafeArea)
            }

            private var materialInsets: EdgeInsets {
                let safeArea = frameForParentView[.navigationStack, default: .zero].safeAreaInsets
                return EdgeInsets(
                    top: 25,
                    leading: viewLayout.edgePadding + safeArea.leading,
                    bottom: 25,
                    trailing: viewLayout.edgePadding + safeArea.trailing
                )
            }

            private var materialHorizontalOffset: CGFloat {
                let offset = (materialInsets.trailing - materialInsets.leading) / 2
                return layoutDirection == .leftToRight ? offset : -offset
            }

            private var logo: some View {
                ImageView(
                    provider.item.imageSource(
                        .logo,
                        itemID: provider.item.id,
                        environment: ImageSourceOptions(maxHeight: 70)
                    )
                )
                .image { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 70, alignment: .bottom)
                }
                .placeholder { _ in
                    EmptyView()
                }
                .failure {
                    Text(provider.item.displayTitle)
                        .fixedSize(horizontal: false, vertical: true)
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                        .lineLimit(viewLayout.isAccessibilitySize ? nil : 2)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.primary)
                }
                .frame(minHeight: 70, alignment: .bottom)
                .accessibilityLabel(provider.item.displayTitle)
                .accessibilityRemoveTraits(.isImage)
            }

            private var overlay: some View {
                VStack(alignment: .center, spacing: 10) {
                    ZStack(alignment: .bottom) {
                        Color.clear
                            .frame(height: max(0, artworkLayout.size.width - 2 * artworkLayout.edgePadding) / headerAspectRatio)

                        logo
                    }
                    .zIndex(10)

                    VStack(alignment: .center, spacing: 10) {
                        MetadataHStack(item: provider.item)

                        ItemView.ActionBar(provider: provider)
                            .frame(maxWidth: 300)

                        ItemView.Description(item: provider.item)

                        ItemView.AttributesHStack(
                            attributes: attributes,
                            item: provider.item,
                            selectedMediaSource: provider.playbackIntent?.mediaSource,
                            alignment: .leading
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundStyle(.secondary)
                    }
                    .edgePadding(.bottom)
                    .background(
                        alignment: .bottom,
                        extendedBy: materialInsets
                    ) {
                        Rectangle()
                            .fill(Material.ultraThin)
                            .mask(gradient: .eased(.easeOut)) {
                                (location: 0, opacity: 0)
                                (location: 0.2, opacity: 1)
                            }
                            .offset(x: materialHorizontalOffset)
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
                            AlternateLayoutView {
                                Color.clear
                            } content: {
                                ImageView(provider.item.imageSource(
                                    .backdrop,
                                    itemID: provider.item.id,
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
                            .frame(
                                width: artworkLayout.size.width,
                                height: artworkLayout.size.width / headerAspectRatio
                            )
                            .clipped()
                            .accessibilityHidden(true)
                            .backport
                            .backgroundExtensionEffect()
                            .bottomEdgeGradient(bottomColor: resolvedColor.wrappedValue)
                        }
                    }
            }
        }
    }
}
