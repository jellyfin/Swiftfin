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

    struct CompactPosterScrollView<Content: View>: ScrollContainerView {

        @Router
        private var router

        @ObservedObject
        private var provider: ItemContentGroupProvider

        @State
        private var bottomColor: Color?

        private let content: Content

        init(
            provider: ItemContentGroupProvider,
            @ViewBuilder content: @escaping () -> Content
        ) {
            self.content = content()
            self.provider = provider
        }

        private func withHeaderImageItem(
            @ViewBuilder content: @escaping (ImageSource, Color?) -> some View
        ) -> some View {

            let item: BaseItemDto = if provider.item.type == .person || provider.item.type == .musicArtist,
                                       let randomItem = provider.randomBackdropItem
            {
                randomItem
            } else {
                provider.item
            }

            let imageType: ImageType = item.type == .episode ? .primary : .backdrop
            let imageSource = item.imageSource(imageType, environment: ImageSourceOptions(maxWidth: 1320))

            return content(imageSource, bottomColor)
                .id(imageSource.url?.hashValue)
                .onChange(of: imageSource.url) { _ in
                    bottomColor = nil
                }
                .animation(.linear(duration: 0.1), value: imageSource.url?.hashValue)
        }

        @ViewBuilder
        private var headerView: some View {
            GeometryReader { proxy in
                withHeaderImageItem { imageSource, gradientColor in
                    ImageView(imageSource)
                        .resolvedColor($bottomColor)
                        .aspectRatio(1.77, contentMode: .fill)
                        .frame(width: proxy.size.width, height: proxy.size.height * 0.78, alignment: .top)
                        .bottomEdgeGradient(bottomColor: gradientColor ?? Color.secondarySystemFill)
                }
            }
        }

        var body: some View {
            OffsetScrollView(heightRatio: 0.45) {
                headerView
            } overlay: {
                OverlayView(provider: provider)
                    .edgePadding(.horizontal)
                    .edgePadding(.bottom)
                    .frame(maxWidth: .infinity)
                    .background {
                        BlurView(style: .systemThinMaterialDark)
                            .maskLinearGradient {
                                (location: 0.2, opacity: 0)
                                (location: 0.3, opacity: 0.5)
                                (location: 0.55, opacity: 1)
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

// TODO: have action buttons part of the right shelf view
//       - possible on leading edge instead

extension ItemView.CompactPosterScrollView {

    struct OverlayView: View {

        @StoredValue(.User.itemViewAttributes)
        private var attributes

        @Router
        private var router

        @ObservedObject
        var provider: ItemContentGroupProvider

        @ViewBuilder
        private var rightShelfView: some View {
            VStack(alignment: .leading) {

                Text(provider.item.displayTitle)
                    .font(.title2)
                    .lineLimit(2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                DotHStack {
                    if provider.item.type == .person {
                        if let birthday = provider.item.birthday {
                            Text(
                                birthday,
                                format: .age.death(provider.item.deathday)
                            )
                        }
                    } else {
                        if provider.item.isUnaired {
                            if let premiereDateLabel = provider.item.airDateLabel {
                                Text(premiereDateLabel)
                            }
                        } else {
                            if let productionYear = provider.item.premiereDateYear {
                                Text(String(productionYear))
                            }
                        }

                        if let playButtonitem = provider.playButtonItem, let runtime = playButtonitem.runTimeLabel {
                            Text(runtime)
                        }
                    }
                }
                .lineLimit(1)
                .font(.subheadline.weight(.medium))
                .foregroundColor(Color(UIColor.lightGray))

                ItemView.AttributesHStack(
                    attributes: attributes,
                    item: provider.item,
                    selectedMediaSource: provider.selectedMediaSource,
                    alignment: .leading
                )
            }
        }

        var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .bottom, spacing: 12) {

                    PosterImage(
                        item: provider.item,
                        type: .portrait,
                        contentMode: .fit
                    )
                    .environment(\.isOverComplexContent, true)
                    .frame(width: 130)
                    .accessibilityIgnoresInvertColors()

                    rightShelfView
                        .padding(.bottom)
                }

                HStack(alignment: .center) {

                    if provider.item.presentPlayButton {
                        ItemView.PlayButton(provider: provider)
                            .frame(width: 130)
                    }

                    Spacer()

                    ItemView.ActionButtonHStack(provider: provider, equalSpacing: false)
                        .foregroundStyle(.white)
                }
                .frame(height: 45)
            }
        }
    }
}
