//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension ItemView {

    struct CompactLogoScrollView<Content: View>: View {

        @EnvironmentObject
        var itemRouter: ItemCoordinator.Router
        @ObservedObject
        var viewModel: ItemViewModel

        let content: () -> Content

        @ViewBuilder
        private var headerView: some View {
            VStack {
                ImageView(viewModel.item.imageSource(.backdrop, maxWidth: UIScreen.main.bounds.width))
//                ImageView(
//                    viewModel.item.getBackdropImage(maxWidth: Int(UIScreen.main.bounds.width)),
//                    blurHash: viewModel.item.getBackdropImageBlurHash()
//                )

                Spacer()
                    .frame(height: 10)
            }
        }

        @ViewBuilder
        private var staticOverlayView: some View {
            StaticOverlayView(viewModel: viewModel)
        }

        var body: some View {
            ParallaxHeaderScrollView(
                header: headerView,
                staticOverlayView: staticOverlayView,
                headerHeight: UIScreen.main.bounds.height * 0.3
            ) {
                VStack(alignment: .center, spacing: 0) {

                    SubOverlayView(viewModel: viewModel)

                    content()
                        .padding(.top)
                }
            }
        }
    }
}

extension ItemView.CompactLogoScrollView {

    struct StaticOverlayView: View {

        @ObservedObject
        var viewModel: ItemViewModel

        var body: some View {
            ZStack {
                VStack {
                    Spacer()

                    LinearGradient(gradient: Gradient(stops: [
                        .init(color: .init(UIColor.black), location: 0),
                        .init(color: .init(UIColor.black), location: 0.2),
                        .init(color: .init(UIColor.black).opacity(0), location: 1),
                    ]), startPoint: .bottom, endPoint: .top)
                        .frame(height: 100)
                }

                VStack {
                    Spacer()
                    
                    ImageView(viewModel.item.imageURL(.logo, maxWidth: UIScreen.main.bounds.width),
                              resizingMode: .aspectFit) {
                        Text(viewModel.item.displayName)
                            .font(.largeTitle)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.primary)
                            .frame(alignment: .bottom)
                    }
                    .frame(maxHeight: 100, alignment: .bottom)
                }
                .padding(.horizontal)
            }
        }
    }
}

extension ItemView.CompactLogoScrollView {

    struct SubOverlayView: View {

        @EnvironmentObject
        var itemRouter: ItemCoordinator.Router
        @ObservedObject
        var viewModel: ItemViewModel

        var body: some View {
            ZStack {
                //				Color(UIColor.lightGray)

                VStack(alignment: .center, spacing: 10) {
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
                    .foregroundColor(.secondary)
                    .padding(.horizontal)

                    ItemView.AttributesHStack(viewModel: viewModel)

                    ItemView.PlayButton(viewModel: viewModel)
                        .frame(maxWidth: 300)
                        .frame(height: 50)

                    ItemView.ActionButtonHStack(viewModel: viewModel)
                        .font(.title)
                        .frame(maxWidth: 300)
                }
                .padding(.horizontal)
            }
        }
    }
}
