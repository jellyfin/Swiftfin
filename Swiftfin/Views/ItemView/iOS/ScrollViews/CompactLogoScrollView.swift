//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
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

        private var topOpacity: CGFloat {
            let start = UIScreen.main.bounds.height * 0.25
            let end = UIScreen.main.bounds.height * 0.42 - 50
            let diff = end - start
            let opacity = clamp((scrollViewOffset - start) / diff, min: 0, max: 1)
            return opacity
        }

        @ViewBuilder
        private var headerView: some View {
            ImageView(viewModel.item.imageSource(.backdrop, maxWidth: UIScreen.main.bounds.width))
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
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    VStack {
                        Spacer()

                        OverlayView(viewModel: viewModel, scrollViewOffset: $scrollViewOffset)
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
                            .overlay {
                                Color.systemBackground
                                    .opacity(topOpacity)
                            }
                    }
                    .frame(height: UIScreen.main.bounds.height * 0.5)

                    ItemView.OverviewView(item: viewModel.item)
                        .overviewLineLimit(4)
                        .taglineLineLimit(2)
                        .padding(.top)
                        .padding(.horizontal)

                    content()
                        .padding(.vertical)
                }
            }
            .edgesIgnoringSafeArea(.top)
            .scrollViewOffset($scrollViewOffset)
            .navBarOffset(
                $scrollViewOffset,
                start: UIScreen.main.bounds.height * 0.42 - 50,
                end: UIScreen.main.bounds.height * 0.42
            )
            .backgroundParallaxHeader(
                $scrollViewOffset,
                height: UIScreen.main.bounds.height * 0.5,
                multiplier: 0.3
            ) {
                headerView
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.isLoading {
                        ProgressView()
                    }
                }
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

        @Binding
        var scrollViewOffset: CGFloat

        var body: some View {
            VStack(alignment: .center, spacing: 10) {
                ImageView(viewModel.item.imageURL(.logo, maxWidth: UIScreen.main.bounds.width, maxHeight: 100))
                    .resizingMode(.aspectFit)
                    .placeholder {
                        EmptyView()
                    }
                    .failure {
                        Text(viewModel.item.displayTitle)
                            .font(.largeTitle)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 100)

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

                ItemView.AttributesHStack(viewModel: viewModel)

                ItemView.PlayButton(viewModel: viewModel)
                    .frame(maxWidth: 300)
                    .frame(height: 50)

                ItemView.ActionButtonHStack(viewModel: viewModel)
                    .font(.title)
                    .frame(maxWidth: 300)
                    .foregroundColor(.white)
            }
        }
    }
}
