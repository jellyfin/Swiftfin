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

    struct CompactPosterScrollView<Content: View>: View {

        @EnvironmentObject
        private var router: ItemCoordinator.Router

        @ObservedObject
        var viewModel: ItemViewModel

        @State
        private var scrollViewOffset: CGFloat = 0
        @State
        private var blurHashBottomEdgeColor: Color = .secondarySystemFill

        let content: () -> Content

        private var topOpacity: CGFloat {
            let start = UIScreen.main.bounds.height * 0.20
            let end = UIScreen.main.bounds.height * 0.4
            let diff = end - start
            let opacity = clamp((scrollViewOffset - start) / diff, min: 0, max: 1)
            return opacity
        }

        @ViewBuilder
        private var headerView: some View {
            ImageView(viewModel.item.imageSource(.backdrop, maxWidth: UIScreen.main.bounds.width))
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
            OffsetScrollView(headerHeight: 0.45) {
                headerView
            } overlay: {
                VStack {
                    Spacer()

                    OverlayView(viewModel: viewModel)
                        .edgePadding(.horizontal)
                        .edgePadding(.bottom)
                        .background {
                            BlurView(style: .systemThinMaterialDark)
                                .mask {
                                    LinearGradient(
                                        stops: [
                                            .init(color: .white.opacity(0), location: 0.2),
                                            .init(color: .white.opacity(0.5), location: 0.3),
                                            .init(color: .white, location: 0.55),
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

extension ItemView.CompactPosterScrollView {

    struct OverlayView: View {

        @EnvironmentObject
        private var router: ItemCoordinator.Router

        @ObservedObject
        var viewModel: ItemViewModel

        @ViewBuilder
        private var rightShelfView: some View {
            VStack(alignment: .leading) {

                Text(viewModel.item.displayTitle)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                DotHStack {
                    if viewModel.item.isUnaired {
                        if let premiereDateLabel = viewModel.item.airDateLabel {
                            Text(premiereDateLabel)
                        }
                    } else {
                        if let productionYear = viewModel.item.productionYear {
                            Text(String(productionYear))
                        }
                    }

                    if let playButtonitem = viewModel.playButtonItem, let runtime = playButtonitem.runTimeLabel {
                        Text(runtime)
                    }
                }
                .lineLimit(1)
                .font(.subheadline.weight(.medium))
                .foregroundColor(Color(UIColor.lightGray))

                ItemView.AttributesHStack(viewModel: viewModel)
            }
        }

        var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .bottom, spacing: 12) {

                    ImageView(viewModel.item.imageSource(.primary, maxWidth: 130))
                        .failure {
                            SystemImageContentView(systemName: viewModel.item.systemImage)
                        }
                        .posterStyle(.portrait, contentMode: .fit)
                        .frame(width: 130)
                        .accessibilityIgnoresInvertColors()

                    rightShelfView
                        .padding(.bottom)
                }

                HStack(alignment: .center) {

                    ItemView.PlayButton(viewModel: viewModel)
                        .frame(width: 130, height: 40)

                    Spacer()

                    ItemView.ActionButtonHStack(viewModel: viewModel, equalSpacing: false)
                        .font(.title2)
                        .foregroundColor(.white)
                }
            }
        }
    }
}
