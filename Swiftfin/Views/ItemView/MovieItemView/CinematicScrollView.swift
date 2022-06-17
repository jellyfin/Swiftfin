//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension MovieItemView {
    
    struct CinematicScrollView: View {
        
        @EnvironmentObject
        var itemRouter: ItemCoordinator.Router
        @EnvironmentObject
        private var viewModel: MovieItemViewModel
        
        @ViewBuilder
        private var headerView: some View {
            ImageView(viewModel.item.getPrimaryImage(maxWidth: Int(UIScreen.main.bounds.width)),
                      blurHash: viewModel.item.getPrimaryImageBlurHash())
        }
        
        @ViewBuilder
        private var staticOverlayView: some View {
            PortraitCinematicHeaderView(viewModel: viewModel)
        }
        
        var body: some View {
            ParallaxHeaderScrollView(header: headerView,
                                     staticOverlayView: staticOverlayView,
                                     headerHeight: UIScreen.main.bounds.height * 0.7) {
                BodyView()
                    .environmentObject(viewModel)
            }
        }
    }
}
