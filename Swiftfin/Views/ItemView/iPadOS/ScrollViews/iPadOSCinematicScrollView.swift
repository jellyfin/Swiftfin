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

        @ObservedObject
        var viewModel: ItemViewModel

        let content: () -> Content

        @ViewBuilder
        private var headerView: some View {
            ImageView(viewModel.item.imageViewSource(.backdrop, maxWidth: UIScreen.main.bounds.width))
//            ImageView(
//                viewModel.item.getBackdropImage(maxWidth: Int(UIScreen.main.bounds.width)),
//                blurHash: viewModel.item.getPrimaryImageBlurHash()
//            )
        }

        @ViewBuilder
        private var staticOverlayView: some View {
            StaticOverlayView(viewModel: viewModel)
        }

        var body: some View {
            ParallaxHeaderScrollView(
                header: headerView,
                staticOverlayView: staticOverlayView,
                headerHeight: UIScreen.main.bounds.height * 0.8
            ) {
                content()
            }
        }
    }
}

extension ItemView.iPadOSCinematicScrollView {

    struct StaticOverlayView: View {

        @EnvironmentObject
        private var itemRouter: ItemCoordinator.Router
        @ObservedObject
        var viewModel: ItemViewModel

        var body: some View {
            VStack {
                Spacer()

                HStack {
                    ImageView(
                        viewModel.item.getLogoImage(maxWidth: 500),
                        resizingMode: .aspectFit,
                        failureView: {
                            Text(viewModel.item.displayName)
                                .font(.largeTitle)
                                .fontWeight(.semibold)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                                .foregroundColor(.white)
                        }
                    )
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.5, maxHeight: 150)

                    Spacer()
                }
                .padding(.horizontal)
                .padding(.horizontal)

                HStack(alignment: .top) {

                    VStack(spacing: 10) {
                        ItemView.PlayButton(viewModel: viewModel)
                            .frame(height: 50)

                        ItemView.ActionButtonHStack(viewModel: viewModel)
                            .font(.title)
                    }
                    .frame(width: 250)
                    .padding(.trailing)

                    VStack(alignment: .leading) {

                        DotHStack {
                            if let firstGenre = viewModel.item.genres?.first {
                                Text(firstGenre)
                            }

                            if let premiereYear = viewModel.item.premiereDateYear {
                                Text(String(premiereYear))
                            }

                            if let playButtonitem = viewModel.playButtonItem, let runtime = playButtonitem.getItemRuntime() {
                                Text(runtime)
                            }
                        }
                        .font(.caption)
                        .foregroundColor(Color(UIColor.lightGray))

                        if let playButtonOverview = viewModel.playButtonItem?.overview {
                            TruncatedTextView(
                                playButtonOverview,
                                lineLimit: 2,
                                font: UIFont.preferredFont(forTextStyle: .subheadline)
                            ) {
                                itemRouter.route(to: \.itemOverview, viewModel.item)
                            }
                            .foregroundColor(.white)
                        } else if let seriesOverview = viewModel.item.overview {
                            TruncatedTextView(
                                seriesOverview,
                                lineLimit: 2,
                                font: UIFont.preferredFont(forTextStyle: .subheadline)
                            ) {
                                itemRouter.route(to: \.itemOverview, viewModel.item)
                            }
                            .foregroundColor(.white)
                        }

                        ItemView.AttributesHStack(viewModel: viewModel)
                    }
                    .padding(.trailing, 200)

                    Spacer()
                }
                .padding()
                .padding()
            }
            .background {
                BlurView(style: .systemThinMaterialDark)
                    .mask {
                        LinearGradient(gradient: Gradient(stops: [
                            .init(color: .white, location: 0),
                            .init(color: .white, location: 0.3),
                            .init(color: .white.opacity(0), location: 0.5),
                        ]), startPoint: .bottom, endPoint: .top)
                    }
            }
        }
    }
}
