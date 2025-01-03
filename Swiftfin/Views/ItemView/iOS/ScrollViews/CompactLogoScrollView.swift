//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import BlurHashKit
import SwiftUI

extension ItemView {

    struct CompactLogoScrollView<Content: View>: View {

        @EnvironmentObject
        private var router: ItemCoordinator.Router

        @ObservedObject
        var viewModel: ItemViewModel

        @State
        private var scrollViewOffset: CGFloat = 0
        @State
        private var blurHashBottomEdgeColor: Color = .secondarySystemFill

        let content: () -> Content

        @ViewBuilder
        private var headerView: some View {
            ImageView(viewModel.item.imageSource(.backdrop, maxHeight: UIScreen.main.bounds.height * 0.35))
                .aspectRatio(1.77, contentMode: .fill)
                .frame(height: UIScreen.main.bounds.height * 0.35)
                .bottomEdgeGradient(bottomColor: blurHashBottomEdgeColor)
                .onAppear {
                    if let backdropBlurHash = viewModel.item.blurHash(.backdrop) {
                        let bottomRGB = BlurHash(string: backdropBlurHash)!.averageLinearRGB
                        blurHashBottomEdgeColor = Color(
                            red: Double(bottomRGB.0),
                            green: Double(bottomRGB.1),
                            blue: Double(bottomRGB.2)
                        )
                    }
                }
        }

        var body: some View {
            OffsetScrollView(headerHeight: 0.5) {
                headerView
            } overlay: {
                VStack {
                    Spacer()

                    OverlayView(viewModel: viewModel)
                        .padding(.horizontal)
                        .padding(.bottom)
                        .background {
                            BlurView(style: .systemThinMaterialDark)
                                .mask {
                                    LinearGradient(
                                        stops: [
                                            .init(color: .clear, location: 0),
                                            .init(color: .black, location: 0.3),
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                }
                        }
                }
            } content: {
                VStack(alignment: .leading, spacing: 10) {

                    ItemView.OverviewView(item: viewModel.item)
                        .overviewLineLimit(4)
                        .taglineLineLimit(2)
                        .padding(.horizontal)

                    RowDivider()

                    content()
                }
                .edgePadding(.vertical)
            }
        }
    }
}

extension ItemView.CompactLogoScrollView {

    struct OverlayView: View {

        @EnvironmentObject
        private var router: ItemCoordinator.Router

        @ObservedObject
        var viewModel: ItemViewModel

        var body: some View {
            VStack(alignment: .center, spacing: 10) {
                ImageView(viewModel.item.imageURL(.logo, maxHeight: 70))
                    .placeholder { _ in
                        EmptyView()
                    }
                    .failure {
                        MaxHeightText(text: viewModel.item.displayTitle, maxHeight: 70)
                            .font(.largeTitle.weight(.semibold))
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white)
                    }
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 70, alignment: .bottom)

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

                ItemView.AttributesHStack(viewModel: viewModel)

                ItemView.PlayButton(viewModel: viewModel)
                    .frame(maxWidth: 300)
                    .frame(height: 50)

                ItemView.ActionButtonHStack(viewModel: viewModel)
                    .font(.title)
                    .frame(maxWidth: 300)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity, alignment: .bottom)
        }
    }
}
