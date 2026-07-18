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

            private let headerAspectRatio = 2.0

            private var headerImageItem: BaseItemDto {
                if provider.item.type == .person || provider.item.type == .musicArtist,
                   let randomItem = provider.randomBackdropItem
                {
                    randomItem
                } else {
                    provider.item
                }
            }

            @ViewBuilder
            private var logo: some View {
                ImageView(
                    provider.item.imageSource(
                        .logo,
                        environment: ImageSourceOptions(maxHeight: 70)
                    )
                )
                .image { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 70)
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
            }

            @ViewBuilder
            private var overlay: some View {
                HStack(alignment: .bottom, spacing: EdgeInsets.edgePadding) {
                    VStack(alignment: .center, spacing: 5) {
                        VStack(alignment: .leading) {
                            if let parentID = provider.item.parentRootID, let parentTitle = provider.item.parentTitle {
                                ParentButton(title: parentTitle, id: parentID)
                            }

                            logo
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        if provider.item.type == .person || provider.item.type == .musicArtist {
                            ImageView(provider.item.imageSource(.primary, environment: ImageSourceOptions(maxWidth: 200)))
                                .failure {
                                    SystemImageContentView(systemName: provider.item.systemImage)
                                }
                                .posterStyle(.portrait, contentMode: .fit)
                                .frame(width: 200)
                                .accessibilityIgnoresInvertColors()
                        }

                        if provider.item.presentPlayButton {
                            PlayButton(provider: provider)
                        }

                        ItemView.ActionButtonHStack(provider: provider)
                    }
                    .frame(maxWidth: 300)

                    VStack(alignment: .leading, spacing: 10) {
                        ItemView.Description(item: provider.item)

                        HStack(alignment: .top) {
                            ItemView.AttributesHStack(
                                attributes: attributes,
                                item: provider.item,
                                selectedMediaSource: provider.selectedMediaSource,
                                alignment: .leading
                            )

                            MetadataHStack(item: provider.item)
                        }
                        .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                .edgePadding(.bottom)
                .background(
                    alignment: .bottom,
                    extendedBy: .init(horizontal: EdgeInsets.edgePadding)
                ) {
                    Rectangle()
                        .fill(Material.ultraThin)
                        .mask(gradient: .eased(.easeOut)) {
                            (location: 0, opacity: 0)
                            (location: 1, opacity: 1)
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
                AlternateLayoutView(alignment: .bottom) {
                    Color.clear
                        .aspectRatio(headerAspectRatio, contentMode: .fit)
                } content: {
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
                            ImageView(headerImageItem.landscapeImageSources(environment: .init(maxWidth: 1920)))
                                .image { (image: UIImage) in
                                    Image(uiImage: image)
                                        .resizable()
                                        .aspectRatio(1.77, contentMode: .fill)
                                        .onAppear {
                                            resolveColor(from: image, binding: resolvedColor)
                                        }
                                }
                        }
                        .aspectRatio(headerAspectRatio, contentMode: .fit)
                        .bottomEdgeGradient(bottomColor: resolvedColor.wrappedValue)
                        .accessibilityHidden(true)
                    }
                }
            }
        }
    }
}
