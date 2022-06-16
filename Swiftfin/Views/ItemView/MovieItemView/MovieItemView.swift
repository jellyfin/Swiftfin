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

struct MovieItemView: View {

	@EnvironmentObject
	var itemRouter: ItemCoordinator.Router
	@EnvironmentObject
	private var viewModel: MovieItemViewModel
    @Default(.itemViewType)
    private var itemViewType
    
    // MARK: Header Views

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
    private var compactLogoHeaderView: some View {
        VStack {
            ImageView(viewModel.item.getBackdropImage(maxWidth: Int(UIScreen.main.bounds.width)),
                      blurHash: viewModel.item.getBackdropImageBlurHash())

            Spacer()
                .frame(height: 10)
        }
    }
    
    @ViewBuilder
    private var testOverlay: some View {
        ZStack {
            VStack {
                Spacer()
                
                LinearGradient(gradient: Gradient(stops: [
                    .init(color: .systemBackground, location: 0),
                    .init(color: .systemBackground, location: 0.2),
                    .init(color: .systemBackground.opacity(0), location: 1),
                ]), startPoint: .bottom, endPoint: .top)
                .frame(height: 100)
            }
            
            VStack {
                Spacer()
                
                ImageView(viewModel.item.getLogoImage(maxWidth: Int(UIScreen.main.bounds.width)),
                          resizingMode: .aspectFit,
                          failureView: {
                              Text(viewModel.getItemDisplayName())
                                  .font(.largeTitle)
                                  .fontWeight(.semibold)
                                  .multilineTextAlignment(.center)
                                  .foregroundColor(.primary)
                                  .frame(alignment: .bottom)
                          })
                          .frame(height: 100, alignment: .bottom)
            }
        }
    }
    
    // MARK: Scroll Views
    
    @ViewBuilder
    private var compactScrollView: some View {
        ParallaxHeaderScrollView(header: compactHeaderView,
                                 staticOverlayView: PortraitCompactOverlayView(viewModel: viewModel),
                                 headerHeight: UIScreen.main.bounds.height * 0.35) {
            MovieItemBodyView()
                .environmentObject(viewModel)
        }
    }
    
    @ViewBuilder
    private var cinematicScrollView: some View {
        ParallaxHeaderScrollView(header: cinematicHeaderView,
                                 staticOverlayView: PortraitCinematicHeaderView(viewModel: viewModel),
                                 headerHeight: UIScreen.main.bounds.height * 0.7) {
            MovieItemBodyView()
                .environmentObject(viewModel)
        }
         .applyItemViewToolbar(with: viewModel)
    }
    
    @ViewBuilder
    private var compactLogoScrollView: some View {
        ParallaxHeaderScrollView(header: compactLogoHeaderView,
                                 staticOverlayView: testOverlay,
                                 headerHeight: UIScreen.main.bounds.height * 0.25) {
            VStack(alignment: .center) {

                CompactLogoSubOverlayView(viewModel: viewModel)
                
                if let itemOverview = viewModel.item.overview {
                    TruncatedTextView(itemOverview,
                                      lineLimit: 4,
                                      font: UIFont.preferredFont(forTextStyle: .footnote)) {
                        itemRouter.route(to: \.itemOverview, viewModel.item)
                    }
                                      .padding(.horizontal)
                                      .padding(.top)
                }
                
                MovieItemBodyView()
                    .environmentObject(viewModel)
            }
        }
        .applyItemViewToolbar(with: viewModel)
    }

	// MARK: Body

	var body: some View {
        Group {
            switch itemViewType {
            case .compactPoster:
                compactScrollView
            case .compactLogo:
                compactLogoScrollView
            case .cinematic:
                cinematicScrollView
            }
        }
	}
}
