//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import BlurHashKit
import SwiftUI

extension ItemView {

    struct CompactPosterScrollView<Content: View>: View {

        @EnvironmentObject
        private var itemRouter: ItemCoordinator.Router
        @State
        private var scrollViewOffset: CGFloat = 0
        @State
        private var blurHashBottomEdgeColor: Color = .secondarySystemFill
        @ObservedObject
        var viewModel: ItemViewModel

        let content: () -> Content

        private var topOpacity: CGFloat {
            let start = UIScreen.main.bounds.height * 0.20
            let end = UIScreen.main.bounds.height * 0.4
            let diff = end - start
            let opacity = min(max((scrollViewOffset - start) / diff, 0), 1)
            return opacity
        }

        @ViewBuilder
        private var headerView: some View {
            ImageView(viewModel.item.imageSource(.backdrop, maxWidth: UIScreen.main.bounds.width))
                .frame(height: UIScreen.main.bounds.height * 0.35)
                .bottomEdgeGradient(bottomColor: blurHashBottomEdgeColor)
        }

        var body: some View {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Color.clear
                        .frame(height: UIScreen.main.bounds.height * 0.15)

                    OverlayView(scrollViewOffset: $scrollViewOffset, viewModel: viewModel)
                        .padding(.horizontal)
                        .padding(.bottom)
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
                        .overlay {
                            Color.systemBackground
                                .opacity(topOpacity)
                        }

                    VStack(alignment: .leading, spacing: 10) {
                        if let firstTagline = viewModel.item.taglines?.first {
                            Text(firstTagline)
                                .font(.body)
                                .fontWeight(.semibold)
                                .multilineTextAlignment(.leading)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        if let itemOverview = viewModel.item.overview {
                            TruncatedTextView(text: itemOverview) {
                                itemRouter.route(to: \.itemOverview, viewModel.item)
                            }
                            .font(.footnote)
                            .lineLimit(4)
                            .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    .frame(maxWidth: .infinity)
                    .background(Color.systemBackground)
                    .foregroundColor(.white)

                    content()
                        .padding(.vertical)
                        .background(Color.systemBackground)
                }
            }
            .edgesIgnoringSafeArea(.top)
            .scrollViewOffset($scrollViewOffset)
            .navBarOffset(
                $scrollViewOffset,
                start: UIScreen.main.bounds.height * 0.28,
                end: UIScreen.main.bounds.height * 0.28 + 50
            )
            .backgroundParallaxHeader(
                $scrollViewOffset,
                height: UIScreen.main.bounds.height * 0.35,
                multiplier: 0.8
            ) {
                headerView
            }
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
    }
}

extension ItemView.CompactPosterScrollView {

    struct OverlayView: View {

        @EnvironmentObject
        private var itemRouter: ItemCoordinator.Router
        @Binding
        var scrollViewOffset: CGFloat
        @ObservedObject
        var viewModel: ItemViewModel

        @ViewBuilder
        private var rightShelfView: some View {
            VStack(alignment: .leading) {

                // MARK: Name

                Text(viewModel.item.displayName)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                // MARK: Details

                DotHStack {
                    if viewModel.item.unaired {
                        if let premiereDateLabel = viewModel.item.airDateLabel {
                            Text(premiereDateLabel)
                        }
                    } else {
                        if let productionYear = viewModel.item.productionYear {
                            Text(String(productionYear))
                        }
                    }

                    if let playButtonitem = viewModel.playButtonItem, let runtime = playButtonitem.getItemRuntime() {
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

                    // MARK: Portrait Image

                    ImageView(viewModel.item.imageSource(.primary, maxWidth: 130))
                        .portraitPoster(width: 130)
                        .accessibilityIgnoresInvertColors()

                    rightShelfView
                        .padding(.bottom)
                }

                // MARK: Play

                HStack(alignment: .center) {

                    ItemView.PlayButton(viewModel: viewModel)
                        .frame(width: 130, height: 40)

                    Spacer()

                    ItemView.ActionButtonHStack(viewModel: viewModel, equalSpacing: false)
                        .font(.title2)
                }
            }
        }
    }
}
