//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension ItemView {

    struct CompactPosterScrollView<Content: View>: ScrollContainerView {

        @Router
        private var router

        @ObservedObject
        private var viewModel: ItemViewModel

        private let content: Content

        init(
            viewModel: ItemViewModel,
            @ViewBuilder content: @escaping () -> Content
        ) {
            self.content = content()
            self.viewModel = viewModel
        }

        private func withHeaderImageItem(
            @ViewBuilder content: @escaping (ImageSource, Color) -> some View
        ) -> some View {

            let item: BaseItemDto

            if viewModel.item.type == .person || viewModel.item.type == .musicArtist,
               let typeViewModel = viewModel as? CollectionItemViewModel,
               let randomItem = typeViewModel.randomItem()
            {
                item = randomItem
            } else {
                item = viewModel.item
            }

            let imageType: ImageType = item.type == .episode ? .primary : .backdrop
            let bottomColor = item.blurHash(for: imageType)?.averageLinearColor ?? Color.secondarySystemFill
            let imageSource = item.imageSource(imageType, maxWidth: 1320)

            return content(imageSource, bottomColor)
                .id(imageSource.url?.hashValue)
                .animation(.linear(duration: 0.1), value: imageSource.url?.hashValue)
        }

        @ViewBuilder
        private var headerView: some View {
            GeometryReader { proxy in
                withHeaderImageItem { imageSource, bottomColor in
                    ImageView(imageSource)
                        .aspectRatio(1.77, contentMode: .fill)
                        .frame(width: proxy.size.width, height: proxy.size.height * 0.78, alignment: .top)
                        .bottomEdgeGradient(bottomColor: bottomColor)
                }
            }
        }

        var body: some View {
            OffsetScrollView(heightRatio: 0.45) {
                headerView
            } overlay: {
                OverlayView(viewModel: viewModel)
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
                    ItemView.OverviewView(item: viewModel.item)
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
        var viewModel: ItemViewModel

        @ViewBuilder
        private var rightShelfView: some View {
            VStack(alignment: .leading) {

                Text(viewModel.item.displayTitle)
                    .font(.title2)
                    .lineLimit(2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                DotHStack {
                    if viewModel.item.type == .person {
                        if let birthday = viewModel.item.birthday {
                            Text(
                                birthday,
                                format: .age.death(viewModel.item.deathday)
                            )
                        }
                    } else {
                        if viewModel.item.isUnaired {
                            if let premiereDateLabel = viewModel.item.airDateLabel {
                                Text(premiereDateLabel)
                            }
                        } else {
                            if let productionYear = viewModel.item.premiereDateYear {
                                Text(String(productionYear))
                            }
                        }

                        if let playButtonitem = viewModel.playButtonItem, let runtime = playButtonitem.runTimeLabel {
                            Text(runtime)
                        }
                    }
                }
                .lineLimit(1)
                .font(.subheadline.weight(.medium))
                .foregroundColor(Color(UIColor.lightGray))

                ItemView.AttributesHStack(
                    attributes: attributes,
                    viewModel: viewModel,
                    alignment: .leading
                )
            }
        }

        var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .bottom, spacing: 12) {

                    PosterImage(
                        item: viewModel.item,
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

                    if viewModel.item.presentPlayButton {
                        ItemView.PlayButton(viewModel: viewModel)
                            .frame(width: 130)
                    }

                    Spacer()

                    ItemView.ActionButtonHStack(viewModel: viewModel, equalSpacing: false)
                        .foregroundStyle(.white)
                }
                .frame(height: 45)
            }
        }
    }
}
