//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Introspect
import JellyfinAPI
import SwiftUI

struct ItemView: View {

	@EnvironmentObject
	var itemRouter: ItemCoordinator.Router

	let item: BaseItemDto

	var body: some View {
		Group {
			switch item.itemType {
			case .episode:
				EpisodeItemView()
					.environmentObject(EpisodeItemViewModel(item: item))
			case .series:
				if UIDevice.isIPad {
					iPadOSSeriesItemView()
						.environmentObject(SeriesItemViewModel(item: item))
				} else {
					SeriesItemView()
						.environmentObject(SeriesItemViewModel(item: item))
				}
			case .movie:
				if UIDevice.isIPad {
					iPadOSMovieItemView()
						.environmentObject(MovieItemViewModel(item: item))
				} else {
					MovieItemView()
						.environmentObject(MovieItemViewModel(item: item))
				}
			case .season:
				SeasonItemView()
					.environmentObject(SeasonItemViewModel(item: item))
			default:
				Text("Hello there")
				//                ItemPortraitMainView()
				//                    .environmentObject(ItemViewModel(item: item))
			}
		}
		.navigationBarTitle(item.name ?? "", displayMode: .inline)
	}
}

extension ItemView {
    
    struct PlayButton: View {
        
        @EnvironmentObject
        var itemRouter: ItemCoordinator.Router
        @ObservedObject
        private var viewModel: ItemViewModel
        
        init(viewModel: ItemViewModel) {
            self.viewModel = viewModel
        }
        
        var body: some View {
            Button {
                if let selectedVideoPlayerViewModel = viewModel.selectedVideoPlayerViewModel {
                    itemRouter.route(to: \.videoPlayer, selectedVideoPlayerViewModel)
                } else {
                    LogManager.log.error("Attempted to play item but no playback information available")
                }
            } label: {
                ZStack {
                    Rectangle()
                        .foregroundColor(viewModel.playButtonItem == nil ? Color(UIColor.secondarySystemFill) : Color.jellyfinPurple)
                        .frame(maxWidth: 300, maxHeight: 50)
                        .frame(height: 50)
                        .cornerRadius(10)

                    HStack {
                        Image(systemName: "play.fill")
                            .font(.system(size: 20))
                        Text(viewModel.playButtonText())
                            .font(.callout)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(viewModel.playButtonItem == nil ? Color(UIColor.secondaryLabel) : Color.white)
                }
            }
            .contextMenu {
                if viewModel.playButtonItem != nil, viewModel.item.userData?.playbackPositionTicks ?? 0 > 0 {
                    Button {
                        if let selectedVideoPlayerViewModel = viewModel.selectedVideoPlayerViewModel {
                            selectedVideoPlayerViewModel.injectCustomValues(startFromBeginning: true)
                            itemRouter.route(to: \.videoPlayer, selectedVideoPlayerViewModel)
                        } else {
                            LogManager.log.error("Attempted to play item but no playback information available")
                        }
                    } label: {
                        Label(L10n.playFromBeginning, systemImage: "gobackward")
                    }
                }
            }
        }
    }
}

extension ItemView {
    
    struct AboutView: View {

        @EnvironmentObject
        var itemRouter: ItemCoordinator.Router
        @ObservedObject
        private var viewModel: ItemViewModel
        
        init(viewModel: ItemViewModel) {
            self.viewModel = viewModel
        }

        var body: some View {
            VStack(alignment: .leading) {
                L10n.about.text
                    .font(.title3)
                    .fontWeight(.bold)
                    .accessibility(addTraits: [.isHeader])
                    .padding(.horizontal)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ImageView(viewModel.item.portraitHeaderViewURL(maxWidth: 110),
                                  blurHash: viewModel.item.getPrimaryImageBlurHash())
                            .portraitPoster(width: 110)
                            .accessibilityIgnoresInvertColors()

                        Button {
                            itemRouter.route(to: \.itemOverview, viewModel.item)
                        } label: {
                            ZStack {

                                Color.secondarySystemFill
                                    .cornerRadius(10)

                                VStack(alignment: .leading, spacing: 10) {
                                    Text(viewModel.getItemDisplayName())
                                        .font(.title3)
                                        .fontWeight(.semibold)

                                    Spacer()

                                    if let overview = viewModel.item.overview {
                                        Text(overview)
                                            .lineLimit(4)
                                            .font(.footnote)
                                            .foregroundColor(.secondary)
                                    } else {
                                        L10n.noOverviewAvailable.text
                                            .font(.footnote)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding()
                            }
                            .frame(width: 330)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

}
