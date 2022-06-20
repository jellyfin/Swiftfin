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
import WidgetKit

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

extension ItemView {

    struct AttributesHStackView: View {
        
        @EnvironmentObject
        private var viewModel: ItemViewModel
        
        var body: some View {
            HStack {
                if let officialRating = viewModel.item.officialRating {
                    AttributeOutlineView(text: officialRating)
                }

                if let selectedPlayerViewModel = viewModel.selectedVideoPlayerViewModel {
                    if selectedPlayerViewModel.item.isHD ?? false {
                        AttributeFillView(text: "HD")
                    }
                    
                    if (selectedPlayerViewModel.videoStream.width ?? 0) > 3800 {
                        AttributeFillView(text: "4K")
                    }
                    
                    if selectedPlayerViewModel.audioStreams.contains(where: { $0.channelLayout == "5.1" }) {
                        AttributeFillView(text: "5.1")
                    }
                    
                    if selectedPlayerViewModel.audioStreams.contains(where: { $0.channelLayout == "7.1" }) {
                        AttributeFillView(text: "7.1")
                    }
                    
                    if !selectedPlayerViewModel.subtitleStreams.isEmpty {
                        AttributeOutlineView(text: "CC")
                    }
                }
            }
            .foregroundColor(.secondary)
        }
    }
    
    struct DotHStackView: View {
        
        @EnvironmentObject
        private var viewModel: ItemViewModel
        
        var body: some View {
            HStack {

                if let firstGenre = viewModel.item.genres?.first {
                    Text(firstGenre)

                    Circle()
                        .frame(width: 2, height: 2)
                        .padding(.horizontal, 1)
                }

                if let premiereYear = viewModel.item.premiereDateYear {
                    Text(String(premiereYear))

                    Circle()
                        .frame(width: 2, height: 2)
                        .padding(.horizontal, 1)
                }

                if let playButtonitem = viewModel.playButtonItem, let runtime = playButtonitem.getItemRuntime() {
                    Text(runtime)
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.horizontal)
        }
    }
    
    struct ItemActionHStackView: View {
        
        @EnvironmentObject
        private var viewModel: ItemViewModel
        
        var body: some View {
            HStack(alignment: .center, spacing: 15) {
                Button {
                    UIDevice.impact(.light)
                    viewModel.toggleWatchState()
                } label: {
                    if viewModel.isWatched {
                        Image(systemName: "checkmark.circle.fill")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, Color.jellyfinPurple, Color.jellyfinPurple)
                    } else {
                        Image(systemName: "checkmark.circle")
                            .foregroundStyle(.white, Color(UIColor.lightGray), Color(UIColor.lightGray))
                    }
                }
                .frame(maxWidth: .infinity)
                
                Button {
                    UIDevice.impact(.light)
                    viewModel.toggleFavoriteState()
                } label: {
                    if viewModel.isFavorited {
                        Image(systemName: "heart.fill")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, Color.red, Color.red)
                    } else {
                        Image(systemName: "heart")
                            .foregroundStyle(.white, Color(UIColor.lightGray), Color(UIColor.lightGray))
                    }
                }
                .frame(maxWidth: .infinity)
                
                if viewModel.videoPlayerViewModels.count > 1 {
                    Menu {
                        ForEach(viewModel.videoPlayerViewModels, id: \.versionName) { viewModelOption in
                            Button {
                                viewModel.selectedVideoPlayerViewModel = viewModelOption
                            } label: {
                                if viewModelOption.versionName == viewModel.selectedVideoPlayerViewModel?.versionName {
                                    Label(viewModelOption.versionName ?? L10n.noTitle, systemImage: "checkmark")
                                } else {
                                    Text(viewModelOption.versionName ?? L10n.noTitle)
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "list.dash")
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .font(.title)
        }
    }
}

struct AttributeOutlineView: View {
    
    let text: String
    
    var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(EdgeInsets(top: 1, leading: 4, bottom: 1, trailing: 4))
            .overlay(RoundedRectangle(cornerRadius: 2)
                .stroke(Color(UIColor.lightGray), lineWidth: 1))
    }
}

struct AttributeFillView: View {
    
    let text: String
    
    var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(EdgeInsets(top: 1, leading: 4, bottom: 1, trailing: 4))
            .hidden()
            .background {
                Color(UIColor.lightGray)
                    .cornerRadius(2)
                    .inverseMask(
                        Group {
                            Text(text)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .padding(EdgeInsets(top: 1, leading: 4, bottom: 1, trailing: 4))
                        }
                    )
            }
    }
}
