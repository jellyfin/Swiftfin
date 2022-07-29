//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension ItemView {
    
    struct CompactPosterScrollView<Content: View>: View {
        
        @EnvironmentObject
        private var itemRouter: ItemCoordinator.Router
        @ObservedObject
        var viewModel: ItemViewModel
        @State
        private var scrollViewOffset: CGFloat = 0
        
        let content: () -> Content
        
        @ViewBuilder
        private var headerView: some View {
            ImageView(viewModel.item.imageSource(.backdrop, maxWidth: UIScreen.main.bounds.width))
                .frame(height: UIScreen.main.bounds.height * 0.35)
        }
        
        var body: some View {
            ScrollView(showsIndicators: false) {
                ZStack(alignment: .top) {
                    VStack(spacing: 0) {
                        Color.systemBackground
                            .mask {
                                LinearGradient(gradient: Gradient(stops: [
                                    .init(color: .white, location: 0),
                                    .init(color: .white.opacity(0), location: 0.3),
                                ]), startPoint: .bottom, endPoint: .top)
                            }
                            .frame(height: UIScreen.main.bounds.height * 0.35)
                        
                        Color.systemBackground
                    }
                    
                    VStack(spacing: 10) {
                        Color.clear
                            .frame(height: UIScreen.main.bounds.height * 0.15)
                        
                        StaticOverlayView(scrollViewOffset: $scrollViewOffset, viewModel: viewModel)
                        
                        content()
                    }
                }
            }
            .ignoresSafeArea()
            .scrollViewOffset($scrollViewOffset)
            .navBarOffset($scrollViewOffset,
                          start: UIScreen.main.bounds.height * 0.28,
                          end: UIScreen.main.bounds.height * 0.28 + 50)
            .backgroundParallaxHeader($scrollViewOffset,
                                      height: UIScreen.main.bounds.height * 0.35,
                                      multiplier: 0.8) {
                headerView
            }
        }
    }
}

extension ItemView.CompactPosterScrollView {

    struct StaticOverlayView: View {

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
                    .foregroundColor(.primary)

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
                .foregroundColor(.secondary)

                ItemView.AttributesHStack(viewModel: viewModel)
            }
        }
        
        private var topOpacity: CGFloat {
            let start = UIScreen.main.bounds.height * 0.24
            let end = UIScreen.main.bounds.height * 0.31
            let diff = end - start
            let opacity = min(max((scrollViewOffset - start) / diff, 0), 1)
            return 1 - opacity
        }

        var body: some View {
            VStack(alignment: .leading, spacing: 10) {
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
                .opacity(topOpacity)

                if let firstTagline = viewModel.item.taglines?.first {
                    Text(firstTagline)
                        .font(.body)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
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
                }
            }
            .padding(.horizontal)
        }
    }
}
