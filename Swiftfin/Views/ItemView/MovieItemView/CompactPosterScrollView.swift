//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension MovieItemView {
    
    struct CompactPosterScrollView: View {
        
        @EnvironmentObject
        var itemRouter: ItemCoordinator.Router
        @EnvironmentObject
        private var viewModel: MovieItemViewModel
        
        @ViewBuilder
        private var headerView: some View {
            VStack {
                ImageView(viewModel.item.getBackdropImage(maxWidth: Int(UIScreen.main.bounds.width)),
                          blurHash: viewModel.item.getBackdropImageBlurHash())
                .blur(radius: 2)

                Spacer()
                    .frame(height: 50)
            }
        }
        
        @ViewBuilder
        private var staticOverlayView: some View {
            PortraitCompactOverlayView(viewModel: viewModel)
        }
        
        var body: some View {
            ParallaxHeaderScrollView(header: headerView,
                                     staticOverlayView: staticOverlayView,
                                     headerHeight: UIScreen.main.bounds.height * 0.35) {
                VStack {
                    if let itemOverview = viewModel.item.overview {
                        TruncatedTextView(itemOverview,
                                          lineLimit: 4,
                                          font: UIFont.preferredFont(forTextStyle: .footnote)) {
                            itemRouter.route(to: \.itemOverview, viewModel.item)
                        }
                                          .padding(.horizontal)
                                          .padding(.top)
                    }
                    
                    BodyView()
                        .environmentObject(viewModel)
                }
            }
        }
    }
}
