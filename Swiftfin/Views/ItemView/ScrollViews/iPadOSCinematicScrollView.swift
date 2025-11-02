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

    struct iPadOSCinematicScrollView<Content: View>: ScrollContainerView {

        @ObservedObject
        private var viewModel: ItemViewModel

        @State
        private var globalSize: CGSize = .zero

        private let content: Content

        init(
            viewModel: ItemViewModel,
            @ViewBuilder content: () -> Content
        ) {
            self.content = content()
            self.viewModel = viewModel
        }

        private var imageType: ImageType {
            switch viewModel.item.type {
            case .episode, .musicVideo, .video:
                .primary
            default:
                .backdrop
            }
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

            let bottomColor = item.blurHash(for: imageType)?.averageLinearColor ?? Color.secondarySystemFill
            let imageSource = item.imageSource(imageType, maxWidth: 1920)

            return content(imageSource, bottomColor)
                .id(imageSource.url?.hashValue)
                .animation(.linear(duration: 0.1), value: imageSource.url?.hashValue)
        }

        @ViewBuilder
        private var headerView: some View {
            withHeaderImageItem { imageSource, bottomColor in
                ImageView(imageSource)
                    .aspectRatio(1.77, contentMode: .fill)
                    .bottomEdgeGradient(bottomColor: bottomColor)
            }
        }

        var body: some View {
            OffsetScrollView(
                heightRatio: globalSize.isLandscape ? 0.75 : 0.5
            ) {
                headerView
            } overlay: {
                OverlayView(viewModel: viewModel)
                    .edgePadding()
                    .frame(maxWidth: .infinity)
                    .background {
                        BlurView(style: .systemThinMaterialDark)
                            .maskLinearGradient {
                                (location: 0.4, opacity: 0)
                                (location: 0.8, opacity: 1)
                            }
                    }
            } content: {
                content
                    .padding(.top, 10)
                    .edgePadding(.bottom)
            }
            .trackingSize($globalSize)
        }
    }
}

extension ItemView.iPadOSCinematicScrollView {

    struct OverlayView: View {

        @StoredValue(.User.itemViewAttributes)
        private var attributes

        @ObservedObject
        var viewModel: ItemViewModel

        var body: some View {
            GeometryReader { geometry in
                HStack(alignment: .bottom) {

                    VStack(alignment: .leading, spacing: 20) {

                        ImageView(viewModel.item.imageSource(
                            .logo,
                            maxHeight: 130
                        ))
                        .placeholder { _ in
                            EmptyView()
                        }
                        .failure {
                            Text(viewModel.item.displayTitle)
                                .font(.largeTitle)
                                .fontWeight(.semibold)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                                .foregroundStyle(.white)
                        }
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: geometry.size.width * 0.4, maxHeight: 130, alignment: .bottomLeading)

                        ItemView.OverviewView(item: viewModel.item)
                            .overviewLineLimit(3)
                            .taglineLineLimit(2)
                            .foregroundStyle(.white)

                        if viewModel.item.type != .person {
                            FlowLayout(
                                alignment: .leading,
                                direction: .down,
                                spacing: 30,
                                minRowLength: 1
                            ) {
                                DotHStack {
                                    if let firstGenre = viewModel.item.genres?.first {
                                        Text(firstGenre)
                                    }

                                    if let premiereYear = viewModel.item.premiereDateYear {
                                        Text(premiereYear)
                                    }

                                    if let playButtonitem = viewModel.playButtonItem, let runtime = playButtonitem.runTimeLabel {
                                        Text(runtime)
                                    }
                                }
                                .font(.footnote)
                                .foregroundStyle(Color(UIColor.lightGray))
                                .fixedSize(horizontal: true, vertical: false)

                                ItemView.AttributesHStack(
                                    attributes: attributes,
                                    viewModel: viewModel,
                                    alignment: .leading
                                )
                            }
                        }
                    }
                    .padding(.trailing, geometry.size.width * 0.05)

                    Spacer()

                    VStack(spacing: 10) {
                        if viewModel.item.type == .person || viewModel.item.type == .musicArtist {
                            ImageView(viewModel.item.imageSource(.primary, maxWidth: 200))
                                .failure {
                                    SystemImageContentView(systemName: viewModel.item.systemImage)
                                }
                                .posterStyle(.portrait, contentMode: .fit)
                                .frame(width: 200)
                                .accessibilityIgnoresInvertColors()
                        } else if viewModel.item.presentPlayButton {
                            ItemView.PlayButton(viewModel: viewModel)
                                .frame(height: 50)
                        }

                        ItemView.ActionButtonHStack(viewModel: viewModel)
                            .foregroundStyle(.white)
                            .frame(height: 50)
                    }
                    .frame(width: 250)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
        }
    }
}
