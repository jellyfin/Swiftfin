//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import BlurHashKit
import Defaults
import SwiftUI

extension ItemView {

    struct CinematicScrollView<Content: View>: ScrollContainerView {

        @Default(.Customization.CinematicItemViewType.usePrimaryImage)
        private var usePrimaryImage

        @EnvironmentObject
        private var router: ItemCoordinator.Router

        @ObservedObject
        private var viewModel: ItemViewModel

        private let blurHashBottomEdgeColor: Color
        private let content: Content

        init(
            viewModel: ItemViewModel,
            content: @escaping () -> Content
        ) {
            if let backdropBlurHash = viewModel.item.blurHash(.backdrop) {
                let bottomRGB = BlurHash(string: backdropBlurHash)!.averageLinearRGB
                blurHashBottomEdgeColor = Color(
                    red: Double(bottomRGB.0),
                    green: Double(bottomRGB.1),
                    blue: Double(bottomRGB.2)
                )
            } else {
                blurHashBottomEdgeColor = Color.secondarySystemFill
            }

            self.content = content()
            self.viewModel = viewModel
        }

        @ViewBuilder
        private var headerView: some View {
            ImageView(viewModel.item.imageSource(
                usePrimaryImage ? .primary : .backdrop,
                maxWidth: UIScreen.main.bounds.width
            ))
            .aspectRatio(usePrimaryImage ? (2 / 3) : 1.77, contentMode: .fill)
            .frame(height: UIScreen.main.bounds.height * 0.6)
            .bottomEdgeGradient(bottomColor: blurHashBottomEdgeColor)
        }

        var body: some View {
            OffsetScrollView(headerHeight: 0.75) {
                headerView
            } overlay: {
                VStack {
                    Spacer()

                    OverlayView(viewModel: viewModel)
                        .edgePadding(.horizontal)
                        .padding(.bottom)
                        .background {
                            BlurView(style: .systemThinMaterialDark)
                                .mask {
                                    LinearGradient(
                                        stops: [
                                            .init(color: .white.opacity(0), location: 0),
                                            .init(color: .white, location: 0.3),
                                            .init(color: .white, location: 1),
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                }
                        }
                }
            } content: {
                content
                    .edgePadding(.vertical)
            }
        }
    }
}

extension ItemView.CinematicScrollView {

    struct OverlayView: View {

        @Default(.Customization.CinematicItemViewType.usePrimaryImage)
        private var usePrimaryImage

        @EnvironmentObject
        private var router: ItemCoordinator.Router
        @ObservedObject
        var viewModel: ItemViewModel

        var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .center, spacing: 10) {
                    if !usePrimaryImage {
                        ImageView(viewModel.item.imageURL(.logo, maxHeight: 100))
                            .placeholder { _ in
                                EmptyView()
                            }
                            .failure {
                                MaxHeightText(text: viewModel.item.displayTitle, maxHeight: 100)
                                    .font(.largeTitle.weight(.semibold))
                                    .lineLimit(2)
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.white)
                            }
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 100, alignment: .bottom)
                    }

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
                    .font(.caption)
                    .foregroundColor(Color(UIColor.lightGray))
                    .padding(.horizontal)

                    Group {
                        if viewModel.presentPlayButton {
                            ItemView.PlayButton(viewModel: viewModel)
                                .frame(height: 50)
                        }

                        ItemView.ActionButtonHStack(viewModel: viewModel)
                            .font(.title)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: 300)
                }
                .frame(maxWidth: .infinity)

                ItemView.OverviewView(item: viewModel.item)
                    .overviewLineLimit(3)
                    .taglineLineLimit(2)
                    .foregroundColor(.white)

                ItemView.AttributesHStack(viewModel: viewModel, alignment: .leading)
            }
        }
    }
}
