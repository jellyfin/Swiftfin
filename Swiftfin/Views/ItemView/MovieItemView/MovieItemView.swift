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

	// MARK: portraitHeaderView

    @ViewBuilder
	private var cinematicHeaderView: some View {
		ImageView(viewModel.item.getPrimaryImage(maxWidth: Int(UIScreen.main.bounds.width)),
		          blurHash: viewModel.item.getPrimaryImageBlurHash())
			
	}
    
    @ViewBuilder
    private var compactHeaderView: some View {
        ImageView(viewModel.item.getBackdropImage(maxWidth: Int(UIScreen.main.bounds.width)),
                  blurHash: viewModel.item.getBackdropImageBlurHash())
    }
    
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
    }

	// MARK: innerBody

	var body: some View {
        Group {
            switch itemViewType {
            case .compact:
                compactScrollView
            case .cinematic:
                cinematicScrollView
            }
        }
		.toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 0) {
                        Button {
                            viewModel.toggleWatchState()
                        } label: {
                            if viewModel.isWatched {
                                Image(systemName: "checkmark.circle.fill")
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.white, Color.jellyfinPurple, Color.jellyfinPurple)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.white, Color(UIColor.lightGray), Color(UIColor.lightGray))
                            }
                        }
        
                        Button {
                            viewModel.toggleFavoriteState()
                        } label: {
                            if viewModel.isFavorited {
                                Image(systemName: "heart.circle.fill")
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.white, Color.jellyfinPurple, Color.jellyfinPurple)
                            } else {
                                Image(systemName: "heart.circle.fill")
                                    .foregroundStyle(.white, Color(UIColor.lightGray), Color(UIColor.lightGray))
                            }
                        }
                }
            }
            
            
//			ToolbarItemGroup(placement: .navigationBarTrailing) {
//				Button {
//					viewModel.toggleWatchState()
//				} label: {
//					if viewModel.isWatched {
//						Image(systemName: "checkmark.circle.fill")
//							.symbolRenderingMode(.palette)
//							.foregroundStyle(.white, Color.jellyfinPurple, Color.jellyfinPurple)
//					} else {
//						Image(systemName: "checkmark.circle.fill")
//							.foregroundStyle(.white, Color(UIColor.lightGray), Color(UIColor.lightGray))
//					}
//				}
//
//				Button {
//					viewModel.toggleFavoriteState()
//				} label: {
//					if viewModel.isFavorited {
//						Image(systemName: "heart.circle.fill")
//							.symbolRenderingMode(.palette)
//							.foregroundStyle(.white, Color.jellyfinPurple, Color.jellyfinPurple)
//					} else {
//						Image(systemName: "heart.circle.fill")
//							.foregroundStyle(.white, Color(UIColor.lightGray), Color(UIColor.lightGray))
//					}
//				}
//			}
		}
	}
}
