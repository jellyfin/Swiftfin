//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension ItemView {

    struct iPadOSCinematicScrollView<Content: View>: View {

        @EnvironmentObject
        private var router: ItemCoordinator.Router

        @ObservedObject
        var viewModel: ItemViewModel

        @State
        private var scrollViewOffset: CGFloat = 0

        let content: () -> Content

        private var topOpacity: CGFloat {
            let start = UIScreen.main.bounds.height * 0.45
            let end = UIScreen.main.bounds.height * 0.65
            let diff = end - start
            let opacity = clamp((scrollViewOffset - start) / diff, min: 0, max: 1)
            return opacity
        }

        @ViewBuilder
        private var headerView: some View {
            Group {
                if viewModel.item.type == .episode {
                    ImageView(viewModel.item.imageSource(.primary, maxWidth: 1920))
                } else {
                    ImageView(viewModel.item.imageSource(.backdrop, maxWidth: 1920))
                }
            }
            .frame(height: UIScreen.main.bounds.height * 0.8)
        }

        var body: some View {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    VStack(spacing: 0) {
                        Spacer()

                        OverlayView(viewModel: viewModel)
                            .padding2(.horizontal)
                            .padding2(.bottom)
                    }
                    .frame(height: UIScreen.main.bounds.height * 0.8)
                    .background {
                        BlurView(style: .systemThinMaterialDark)
                            .mask {
                                LinearGradient(
                                    stops: [
                                        .init(color: .clear, location: 0.4),
                                        .init(color: .white, location: 0.8),
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

                    content()
                        .padding(.vertical)
                        .background(Color.systemBackground)
                }
            }
            .edgesIgnoringSafeArea(.top)
            .edgesIgnoringSafeArea(.horizontal)
            .scrollViewOffset($scrollViewOffset)
            .navigationBarOffset(
                $scrollViewOffset,
                start: UIScreen.main.bounds.height * 0.65,
                end: UIScreen.main.bounds.height * 0.65 + 50
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

extension ItemView.iPadOSCinematicScrollView {

    struct OverlayView: View {

        @EnvironmentObject
        private var router: ItemCoordinator.Router

        @ObservedObject
        var viewModel: ItemViewModel

        var body: some View {
            HStack(alignment: .bottom) {

                VStack(alignment: .leading, spacing: 20) {

                    ImageView(viewModel.item.imageSource(
                        .logo,
                        maxWidth: UIScreen.main.bounds.width * 0.4,
                        maxHeight: 130
                    ))
                    .placeholder {
                        EmptyView()
                    }
                    .failure {
                        Text(viewModel.item.displayTitle)
                            .font(.largeTitle)
                            .fontWeight(.semibold)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .foregroundColor(.white)
                    }
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.4, maxHeight: 130, alignment: .bottomLeading)

                    ItemView.OverviewView(item: viewModel.item)
                        .overviewLineLimit(3)
                        .taglineLineLimit(1)
                        .foregroundColor(.white)

                    HStack(spacing: 30) {
                        ItemView.AttributesHStack(viewModel: viewModel)

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
                        .foregroundColor(Color(UIColor.lightGray))
                    }
                }
                .padding(.trailing, 200)

                Spacer()

                VStack(spacing: 10) {
                    ItemView.PlayButton(viewModel: viewModel)
                        .frame(height: 50)

                    ItemView.ActionButtonHStack(viewModel: viewModel)
                        .font(.title)
                        .foregroundColor(.white)
                }
                .frame(width: 250)
            }
        }
    }
}
