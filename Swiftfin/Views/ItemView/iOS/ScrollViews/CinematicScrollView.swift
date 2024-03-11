//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import BlurHashKit
import Defaults
import SwiftUI

extension ItemView {

    struct CinematicScrollView<Content: View>: View {

        @Default(.Customization.CinematicItemViewType.usePrimaryImage)
        private var cinematicItemViewTypeUsePrimaryImage

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
            let start = UIScreen.main.bounds.height * 0.5
            let end = UIScreen.main.bounds.height * 0.65
            let diff = end - start
            let opacity = clamp((scrollViewOffset - start) / diff, min: 0, max: 1)
            return opacity
        }

        @ViewBuilder
        private var headerView: some View {
            ImageView(viewModel.item.imageSource(
                cinematicItemViewTypeUsePrimaryImage ? .primary : .backdrop,
                maxWidth: UIScreen.main.bounds.width
            ))
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
            .navigationBarOffset(
                $scrollViewOffset,
                start: UIScreen.main.bounds.height * 0.66,
                end: UIScreen.main.bounds.height * 0.66 + 50
            )
            .backgroundParallaxHeader(
                $scrollViewOffset,
                height: UIScreen.main.bounds.height * 0.8,
                multiplier: 0.3
            ) {
                headerView
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if viewModel.isLoading {
                        ProgressView()
                    }
                }
            }
        }
    }
}

extension ItemView.CinematicScrollView {

    struct OverlayView: View {

        @Default(.Customization.CinematicItemViewType.usePrimaryImage)
        private var cinematicItemViewTypeUsePrimaryImage

        @EnvironmentObject
        private var router: ItemCoordinator.Router
        @ObservedObject
        var viewModel: ItemViewModel

        var body: some View {
            VStack(alignment: .leading, spacing: 10) {

                VStack(alignment: .center, spacing: 10) {
                    if !cinematicItemViewTypeUsePrimaryImage {
                        ImageView(viewModel.item.imageURL(.logo, maxWidth: UIScreen.main.bounds.width))
//                            .resizingMode(.aspectFit)
                                .placeholder {
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
                                .frame(height: 100)
                                .frame(maxWidth: .infinity)
                    } else {
                        Spacer()
                            .frame(height: 50)
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

                    ItemView.PlayButton(viewModel: viewModel)
                        .frame(maxWidth: 300)
                        .frame(height: 50)

                    ItemView.ActionButtonHStack(viewModel: viewModel)
                        .font(.title)
                        .frame(maxWidth: 300)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)

                ItemView.OverviewView(item: viewModel.item)
                    .overviewLineLimit(4)
                    .taglineLineLimit(2)
                    .foregroundColor(.white)

                ItemView.AttributesHStack(viewModel: viewModel)
            }
        }
    }
}
