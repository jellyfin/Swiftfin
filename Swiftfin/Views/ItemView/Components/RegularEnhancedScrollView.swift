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

        @Router
        private var router

        @StoredValue(.User.itemViewAttributes)
        private var attributes

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
        private func parentButton(_ title: String, id: String) -> some View {
            Button {
                router.route(to: .item(id: id))
            } label: {
                Label {
                    Text(title)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                } icon: {
                    Image(systemName: "chevron.forward")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .font(.callout)
                .fontWeight(.semibold)
            }
            .foregroundStyle(.primary, .secondary)
            .labelStyle(
                CapsuleLabelStyle(
                    isIconTrailing: true
                )
            )
        }

        @ViewBuilder
        private var overlay: some View {
            HStack(alignment: .bottom, spacing: EdgeInsets.edgePadding) {
                VStack(alignment: .center, spacing: 5) {
                    VStack(alignment: .leading) {
                        switch provider.item.type {
                        case .episode:
                            if let parentID = provider.item.seriesID, let parentTitle = provider.item.parentTitle {
                                parentButton(parentTitle, id: parentID)
                            }
                        case .liveTvProgram:
                            if let channelID = provider.item.channelID, let channelName = provider.item.channelName {
                                parentButton(channelName, id: channelID)
                            }
                        default:
                            EmptyView()
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

                            if let seasonEpisodeLabel = provider.item.seasonEpisodeLabel {
                                Text(seasonEpisodeLabel)
                            }
                        }
                        .font(.caption)
                        .fontWeight(.semibold)
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
