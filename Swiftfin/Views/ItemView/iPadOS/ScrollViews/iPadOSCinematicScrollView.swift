//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension ItemView {

    struct iPadOSCinematicScrollView<Content: View>: View {

        @EnvironmentObject
        private var itemRouter: ItemCoordinator.Router
        @State
        private var scrollViewOffset: CGFloat = 0
        @ObservedObject
        var viewModel: ItemViewModel

        let content: () -> Content
        
        private var topOpacity: CGFloat {
            let start = UIScreen.main.bounds.height * 0.45
            let end = UIScreen.main.bounds.height * 0.65
            let diff = end - start
            let opacity = min(max((scrollViewOffset - start) / diff, 0), 1)
            return opacity
        }

        @ViewBuilder
        private var headerView: some View {
            ImageView(viewModel.item.imageSource(.backdrop, maxWidth: UIScreen.main.bounds.width))
                .frame(height: UIScreen.main.bounds.height * 0.8)
        }

        var body: some View {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    VStack(spacing: 0) {
                        Spacer()
                        
                        OverlayView(viewModel: viewModel)
                            .padding(.horizontal)
                            .padding(.horizontal)
                            .padding(.bottom)
                            .padding(.bottom)
                    }
                    .frame(height: UIScreen.main.bounds.height * 0.8)
                    .background {
                        BlurView(style: .systemThinMaterialDark)
                            .mask {
                                LinearGradient(
                                    stops: [
                                        .init(color: .white.opacity(0), location: 0.5),
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
                    
                    content()
                        .padding(.vertical)
                        .background(Color.systemBackground)
                }
            }
            .edgesIgnoringSafeArea(.top)
            .edgesIgnoringSafeArea(.horizontal)
            .scrollViewOffset($scrollViewOffset)
            .navBarOffset($scrollViewOffset,
                          start: UIScreen.main.bounds.height * 0.65,
                          end: UIScreen.main.bounds.height * 0.65 + 50)
            .backgroundParallaxHeader($scrollViewOffset,
                                      height: UIScreen.main.bounds.height * 0.8,
                                      multiplier: 0.3) {
                headerView
            }
            
        }
    }
}

extension ItemView.iPadOSCinematicScrollView {

    struct OverlayView: View {

        @EnvironmentObject
        private var itemRouter: ItemCoordinator.Router
        @ObservedObject
        var viewModel: ItemViewModel

        var body: some View {
            VStack {
                HStack {
                    ImageView(
                        viewModel.item.imageURL(.logo, maxWidth: 500),
                        resizingMode: .aspectFit
                    ) {
                        Text(viewModel.item.displayName)
                            .font(.largeTitle)
                            .fontWeight(.semibold)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.5, maxHeight: 150)

                    Spacer()
                }

                HStack(alignment: .bottom) {

                    VStack(alignment: .leading) {

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

//                        if let playButtonOverview = viewModel.playButtonItem?.overview {
//                            TruncatedTextView(
//                                playButtonOverview,
//                                lineLimit: 2,
//                                font: UIFont.preferredFont(forTextStyle: .subheadline)
//                            ) {
//                                itemRouter.route(to: \.itemOverview, viewModel.item)
//                            }
//                            .foregroundColor(.white)
//                        } else if let seriesOverview = viewModel.item.overview {
//                            TruncatedTextView(
//                                seriesOverview,
//                                lineLimit: 2,
//                                font: UIFont.preferredFont(forTextStyle: .subheadline)
//                            ) {
//                                itemRouter.route(to: \.itemOverview, viewModel.item)
//                            }
//                            .foregroundColor(.white)
//                        }

                        ItemView.AttributesHStack(viewModel: viewModel)
                    }
                    .padding(.trailing, 200)

                    Spacer()
                    
                    VStack(spacing: 10) {
                        ItemView.PlayButton(viewModel: viewModel)
                            .frame(height: 50)

                        ItemView.ActionButtonHStack(viewModel: viewModel)
                            .font(.title)
                    }
                    .frame(width: 250)
                }
            }
        }
    }
}
