//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension ItemView {

    struct CompactLogoScrollView<Content: View>: ScrollContainerView {

        @Router
        private var router

        @ObservedObject
        private var provider: ItemContentGroupProvider

        @State
        private var bottomColor: Color?

        private let content: Content

        init(
            provider: ItemContentGroupProvider,
            content: @escaping () -> Content
        ) {
            self.content = content()
            self.provider = provider
        }

        @ViewBuilder
        private var headerView: some View {
            GeometryReader { proxy in
                ImageView(provider.item.imageSource(.backdrop, environment: ImageSourceOptions(maxWidth: 1320)))
                    .resolvedColor($bottomColor)
                    .aspectRatio(1.77, contentMode: .fill)
                    .frame(width: proxy.size.width, height: proxy.size.height * 0.70, alignment: .top)
                    .bottomEdgeGradient(bottomColor: bottomColor ?? Color.secondarySystemFill)
            }
            .onChange(of: provider.item.imageSource(.backdrop, environment: ImageSourceOptions()).url) { _ in
                bottomColor = nil
            }
        }

        var body: some View {
            OffsetScrollView(heightRatio: 0.5) {
                headerView
            } overlay: {
                OverlayView(provider: provider)
                    .edgePadding(.horizontal)
                    .edgePadding(.bottom)
                    .frame(maxWidth: .infinity)
                    .background {
                        BlurView(style: .systemThinMaterialDark)
                            .maskLinearGradient {
                                (location: 0, opacity: 0)
                                (location: 0.3, opacity: 1)
                            }
                    }
            } content: {
                SeparatorVStack(alignment: .leading) {
                    RowDivider()
                        .padding(.vertical, 10)
                } content: {
                    ItemView.OverviewView(item: provider.item)
                        .overviewLineLimit(4)
                        .taglineLineLimit(2)
                        .edgePadding(.horizontal)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    content
                }
                .edgePadding(.vertical)
            }
        }
    }
}

extension ItemView.CompactLogoScrollView {

    struct OverlayView: View {

        @StoredValue(.User.itemViewAttributes)
        private var attributes

        @Router
        private var router

        @ObservedObject
        var provider: ItemContentGroupProvider

        var body: some View {
            VStack(alignment: .center, spacing: 10) {
                ImageView(provider.item.imageSource(.logo, environment: ImageSourceOptions(maxHeight: 70)))
                    .placeholder { _ in
                        EmptyView()
                    }
                    .failure {
                        Text(provider.item.displayTitle)
                            .font(.largeTitle)
                            .fontWeight(.semibold)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white)
                    }
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 70, alignment: .bottom)

                DotHStack {
                    if let firstGenre = provider.item.genres?.first {
                        Text(firstGenre)
                    }

                    if let premiereYear = provider.item.premiereDateYear {
                        Text(premiereYear)
                    }

                    if let playButtonitem = provider.playButtonItem, let runtime = playButtonitem.runTimeLabel {
                        Text(runtime)
                    }
                }
                .font(.caption)
                .foregroundColor(Color(UIColor.lightGray))
                .padding(.horizontal)

                Group {
                    ItemView.AttributesHStack(
                        attributes: attributes,
                        item: provider.item,
                        selectedMediaSource: provider.selectedMediaSource
                    )

                    if provider.item.presentPlayButton {
                        ItemView.PlayButton(provider: provider)
                            .frame(height: 50)
                    }

                    ItemView.ActionButtonHStack(provider: provider)
                        .foregroundStyle(.white)
                        .frame(height: 50)
                }
                .frame(maxWidth: 300)
            }
        }
    }
}
