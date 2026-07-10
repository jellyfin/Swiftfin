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

        @State
        private var resolvedBottomColor: Color?

        @StoredValue(.User.itemViewAttributes)
        private var attributes

        @ViewBuilder
        private var logo: some View {
            ImageView(
                provider.item.imageSource(
                    .logo,
                    environment: ImageSourceOptions(maxHeight: 100)
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
            .frame(height: 100, alignment: .bottom)
        }

        @ViewBuilder
        private var overlay: some View {
            VStack(alignment: .center, spacing: 10) {
                AlternateLayoutView(alignment: .bottom) {
                    Color.clear
                        .aspectRatio(1.77, contentMode: .fit)
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
                            ItemView.PlayButton(provider: provider)
                                .frame(height: 50)
                        }

                        ItemView.ActionButtonHStack(provider: provider)
                            .frame(height: 50)
                    }
                    .frame(maxWidth: 300)

                    ItemView.OverviewView(item: provider.item)
                        .overviewLineLimit(3)
                        .taglineLineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    ItemView.AttributesHStack(
                        attributes: attributes,
                        item: provider.item,
                        selectedMediaSource: provider.selectedMediaSource,
                        alignment: .leading
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .background(
                    alignment: .bottom,
                    extendedBy: .init(
                        vertical: 25,
                        horizontal: EdgeInsets.edgePadding
                    )
                ) {
                    Rectangle()
//                        .fill(Material.ultraThin)
                            .fill(Color.clear)
                            .mask {
                                EasedGradient(
                                    stops: [
                                        .init(color: .clear, location: 0),
                                        .init(color: .white.opacity(0.7), location: 0.1),
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

        private func resolveColor(from image: UIImage) {
            Task.detached(priority: .utility) {
                let color = image.interestingColor()

                print("Resolved bottom color: \(color) from image: \(image)")

                await MainActor.run {
                    resolvedBottomColor = .blue
                }
            }
        }

        @ViewBuilder
        private var header: some View {
            overlay
                .edgePadding(.horizontal)
                .frame(maxWidth: .infinity)
                .colorScheme(.dark)
                .overlay {
                    Rectangle()
                        .fill(resolvedBottomColor ?? .clear)
                }
                .backgroundParallaxHeader(
                    multiplier: 0.3,
                    backgroundColor: .clear
                ) {
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
                                .onAppear {
                                    resolveColor(from: image)
                                }
                        }
                    }
                    .aspectRatio(1.77, contentMode: .fit)
                    .bottomEdgeGradient(bottomColor: .red)
//                    .bottomEdgeGradient(bottomColor: resolvedBottomColor ?? .clear)
                    .accessibilityHidden(true)
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
