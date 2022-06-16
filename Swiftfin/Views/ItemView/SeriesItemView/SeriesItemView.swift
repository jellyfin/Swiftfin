//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

struct SeriesItemView: View {

	@EnvironmentObject
	var itemRouter: ItemCoordinator.Router
	@EnvironmentObject
	private var viewModel: SeriesItemViewModel
    @Default(.itemViewType)
    private var itemViewType

	// MARK: portraitHeaderView

    @ViewBuilder
    private var cinematicHeaderView: some View {
        ImageView(viewModel.item.getPrimaryImage(maxWidth: Int(UIScreen.main.bounds.width)),
                  blurHash: viewModel.item.getPrimaryImageBlurHash())
    }
    
    @ViewBuilder
    private var compactHeaderView: some View {
        VStack {
            ImageView(viewModel.item.getBackdropImage(maxWidth: Int(UIScreen.main.bounds.width)),
                      blurHash: viewModel.item.getBackdropImageBlurHash())
            .blur(radius: 2)
            
            Spacer()
                .frame(height: 50)
        }
    }
    
    @ViewBuilder
    private var compactScrollView: some View {
        ParallaxHeaderScrollView(header: compactHeaderView,
                                 staticOverlayView: PortraitCompactOverlayView(viewModel: viewModel),
                                 headerHeight: UIScreen.main.bounds.height * 0.35) {
            SeriesItemBodyView()
                .environmentObject(viewModel)
        }
    }
    
    @ViewBuilder
    private var cinematicScrollView: some View {
        ParallaxHeaderScrollView(header: cinematicHeaderView,
                                 staticOverlayView: PortraitCinematicHeaderView(viewModel: viewModel),
                                 headerHeight: UIScreen.main.bounds.height * 0.7) {
            SeriesItemBodyView()
                .environmentObject(viewModel)
        }
                                 .applyItemViewToolbar(with: viewModel)
    }

	// MARK: innerBody

	var body: some View {
        Group {
            switch itemViewType {
            case .compactPoster, .compactLogo:
                compactScrollView
            case .cinematic:
                cinematicScrollView
            }
        }
	}
}
