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
        private var itemRouter: ItemCoordinator.Router
        @ObservedObject
        var viewModel: ItemViewModel

        let content: () -> Content

        @ViewBuilder
        private var headerView: some View {
            VStack {
                ImageView(viewModel.item.imageSource(.backdrop, maxWidth: UIScreen.main.bounds.width))

                Color.red
                    .frame(height: 50)
            }
        }

        @ViewBuilder
        private var staticOverlayView: some View {
            StaticOverlayView(viewModel: viewModel)
        }
        
        @ViewBuilder
        private var overview: some View {
            if let firstTagline = viewModel.item.taglines?.first {
                Text(firstTagline)
                    .font(.body)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
            }

            if let itemOverview = viewModel.item.overview {
                TruncatedTextView(
                    itemOverview,
                    lineLimit: 4,
                    font: UIFont.preferredFont(forTextStyle: .footnote)
                ) {
                    itemRouter.route(to: \.itemOverview, viewModel.item)
                }
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal)
            }
        }

        var body: some View {
            ParallaxHeaderScrollView(
                header: headerView,
                staticOverlay: staticOverlayView,
                headerHeight: UIScreen.main.bounds.height * 0.35
            ) {
                content()
            }
        }
    }
}

extension ItemView.CompactLogoScrollView {

    struct StaticOverlayView: View {

        @ObservedObject
        var viewModel: ItemViewModel

        var body: some View {
            VStack(alignment: .center, spacing: 10) {
                
                Spacer()
                
                ImageView(viewModel.item.imageURL(.logo, maxWidth: UIScreen.main.bounds.width),
                          resizingMode: .aspectFit) {
                    Text(viewModel.item.displayName)
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.primary)
                }
                .frame(maxHeight: 100)
                
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
