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

    struct CinematicScrollView<Content: View>: View {

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
            let start = UIScreen.main.bounds.height * 0.5
            let end = UIScreen.main.bounds.height * 0.65
            let diff = end - start
            let opacity = min(max((scrollViewOffset - start) / diff, 0), 1)
            return opacity
        }

        @ViewBuilder
        private var headerView: some View {
            ImageView(viewModel.item.imageSource(.backdrop, maxWidth: UIScreen.main.bounds.width))
                .frame(height: UIScreen.main.bounds.height * 0.6)
                .bottomEdgeGradient(bottomColor: blurHashBottomEdgeColor)
                .onAppear {
                    if let headerBlurHash = viewModel.item.blurHash(.backdrop) {
                        let bottomRGB = BlurHash(string: headerBlurHash)!.averageLinearRGB
                        blurHashBottomEdgeColor = Color(
                            red: Double(bottomRGB.0),
                            green: Double(bottomRGB.1),
                            blue: Double(bottomRGB.2)
                        )
                    }
                }
        }

        var body: some View {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {

                    VStack(spacing: 0) {
                        Spacer()

                        OverlayView(viewModel: viewModel)
                            .padding(.horizontal)
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
                            .overlay {
                                Color.systemBackground
                                    .opacity(topOpacity)
                            }
                    }
                    .frame(height: UIScreen.main.bounds.height * 0.8)

                    content()
                        .padding(.vertical)
                        .background(Color.systemBackground)
                }
            }
            .edgesIgnoringSafeArea(.top)
            .scrollViewOffset($scrollViewOffset)
            .navBarOffset(
                $scrollViewOffset,
                start: UIScreen.main.bounds.height * 0.66,
                end: UIScreen.main.bounds.height * 0.66 + 50
            )
            .backgroundParallaxHeader(
                $scrollViewOffset,
                height: UIScreen.main.bounds.height * 0.6,
                multiplier: 0.3
            ) {
                headerView
            }
        }
    }
}

extension ItemView.CinematicScrollView {

    struct OverlayView: View {

        @EnvironmentObject
        private var itemRouter: ItemCoordinator.Router
        @ObservedObject
        var viewModel: ItemViewModel

        var body: some View {
            VStack(alignment: .leading, spacing: 10) {

                VStack(alignment: .center, spacing: 10) {
                    ImageView(viewModel.item.imageURL(.logo, maxWidth: UIScreen.main.bounds.width))
                        .resizingMode(.aspectFit)
                        .placeholder {
                            EmptyView()
                        }
                        .failure {
                            Text(viewModel.item.displayName)
                                .font(.largeTitle)
                                .fontWeight(.semibold)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.white)
                        }
                        .frame(height: 100)
                        .frame(maxWidth: .infinity)

                    DotHStack {
                        if let firstGenre = viewModel.item.genres?.first {
                            Text(firstGenre)
                        }

                        if let premiereYear = viewModel.item.premiereDateYear {
                            Text(premiereYear)
                        }

                        if let playButtonitem = viewModel.playButtonItem, let runtime = playButtonitem.getItemRuntime() {
                            Text(runtime)
                        }
                    }
                    .font(.caption)
                    .foregroundColor(Color(UIColor.lightGray))
                    .padding(.horizontal)

                    ItemView.PlayButton(viewModel: viewModel)
                        .frame(maxWidth: 300)
                        .frame(height: 50)

                    ItemView.ActionButtonHStack(viewModel: viewModel)
                        .font(.title)
                        .frame(maxWidth: 300)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)

                if let firstTagline = viewModel.item.taglines?.first {
                    Text(firstTagline)
                        .font(.body)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .foregroundColor(.white)
                }

                if let itemOverview = viewModel.item.overview {
                    TruncatedTextView(text: itemOverview) {
                        itemRouter.route(to: \.itemOverview, viewModel.item)
                    }
                    .font(.footnote)
                    .lineLimit(4)
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
                }

                ItemView.AttributesHStack(viewModel: viewModel)
            }
        }
    }
}
