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

    struct RegularEnhancedHeaderContentGroup: ContentGroup {

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

            private let headerAspectRatio = 2.0

            private var artworkWidth: CGFloat {
                let navigationWidth = frameForParentView[.navigationStack]?.sizeIncludingSafeArea.width ?? 0
                return navigationWidth > 0 ? navigationWidth : viewLayout.size.width
            }

            private var artworkHeight: CGFloat {
                artworkWidth / headerAspectRatio
            }

            private var overlayLayout: AnyLayout {
                if !viewLayout.isLarge, viewLayout.usesCompactDetail {
                    AnyLayout(VStackLayout(alignment: .center, spacing: 10))
                } else {
                    AnyLayout(HStackLayout(alignment: .bottom, spacing: viewLayout.edgePadding))
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

            private var logoHeight: CGFloat {
                viewLayout.value(standard: 70, large: 100)
            }

            private var materialInsets: EdgeInsets {
                let safeArea = frameForParentView[.navigationStack, default: .zero].safeAreaInsets
                return EdgeInsets(
                    top: 0,
                    leading: viewLayout.edgePadding + safeArea.leading,
                    bottom: 0,
                    trailing: viewLayout.edgePadding + safeArea.trailing
                )
            }

            private var materialHorizontalOffset: CGFloat {
                // Match the artwork's full canvas when the safe area is asymmetric.
                let offset = (materialInsets.trailing - materialInsets.leading) / 2
                return layoutDirection == .leftToRight ? offset : -offset
            }

            private var logo: some View {
                ImageView(
                    provider.item.imageSource(
                        .logo,
                        itemID: provider.item.id,
                        environment: ImageSourceOptions(maxHeight: logoHeight)
                    )
                )
                .image { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: logoHeight)
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

            private var overlay: some View {
                overlayLayout {
                    VStack(alignment: .center, spacing: viewLayout.value(standard: 5, large: 30)) {
                        VStack(alignment: .leading) {
                            if let parentID = provider.item.parentRootID, let parentTitle = provider.item.parentTitle {
                                ParentButton(title: parentTitle, id: parentID)
                            }

                            logo
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        ItemView.ActionBar(provider: provider)
                    }
                    .frame(width: viewLayout.value(standard: 300, large: 450))

                    VStack(alignment: .leading, spacing: 10) {
                        ItemView.Description(item: provider.item)

                        HStack(alignment: .top) {
                            ItemView.AttributesHStack(
                                attributes: attributes,
                                item: provider.item,
                                selectedMediaSource: provider.playbackIntent?.mediaSource,
                                alignment: .leading
                            )

                            MetadataHStack(item: provider.item)
                        }
                        .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                .focusSection()
                .if(!viewLayout.isLarge) { content in
                    content
                        .edgePadding(.bottom)
                        .background(
                            alignment: .bottom,
                            extendedBy: materialInsets
                        ) {
                            Rectangle()
                                .fill(Material.ultraThin)
                                .mask(gradient: .eased(.easeOut)) {
                                    (location: 0, opacity: 0)
                                    (location: 1, opacity: 1)
                                }
                                .offset(x: materialHorizontalOffset)
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

            var body: some View {
                if viewLayout.isLarge {
                    CinematicContentGroupContainer {
                        overlay
                            .edgePadding(.horizontal)
                            .frame(maxWidth: .infinity)
                            .colorScheme(.dark)
                    }
                } else {
                    ZStack(alignment: .bottom) {
                        Color.clear
                            .frame(height: artworkHeight)

                        overlay
                            .edgePadding(.horizontal)
                            .frame(maxWidth: .infinity)
                            .colorScheme(.dark)
                    }
                    .backgroundParallaxHeader(multiplier: 0.3) {
                        StateAdapter(initialValue: Color.secondarySystemFill) { resolvedColor in
                            AlternateLayoutView {
                                Color.clear
                            } content: {
                                ImageView(headerImageItem.imageSources(for: .landscape, environment: .init(maxWidth: 1920)))
                                    .image { (image: UIImage) in
                                        Image(uiImage: image)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .onAppear {
                                                resolveColor(from: image, binding: resolvedColor)
                                            }
                                    }
                            }
                            // Keep the image at the navigation container's scale. The
                            // sidebar reveals/crops it instead of zooming it.
                            .frame(width: artworkWidth, height: artworkHeight)
                            .clipped()
                            // Keep the reflection outside the native effect's clip.
                            .backport
                            .backgroundExtensionEffect()
                            .bottomEdgeGradient(bottomColor: resolvedColor.wrappedValue)
                            .accessibilityHidden(true)
                        }
                    }
                }
            }
        }
    }
}
