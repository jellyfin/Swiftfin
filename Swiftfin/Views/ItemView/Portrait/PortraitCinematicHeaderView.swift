//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct PortraitCinematicHeaderView: View {

	@EnvironmentObject
	var itemRouter: ItemCoordinator.Router
	@ObservedObject
	private var viewModel: ItemViewModel

	init(viewModel: ItemViewModel) {
		self.viewModel = viewModel
	}

	var body: some View {
		VStack(alignment: .center) {

			Spacer()

			ImageView(viewModel.item.getLogoImage(maxWidth: Int(UIScreen.main.bounds.width)),
			          resizingMode: .aspectFit,
			          failureView: {
			          	Text(viewModel.getItemDisplayName())
			          		.font(.largeTitle)
			          		.fontWeight(.semibold)
			          		.multilineTextAlignment(.center)
			          		.foregroundColor(.white)
			          		.frame(alignment: .bottom)
			          })
			          .frame(height: 100, alignment: .bottom)

			HStack {

				if let firstGenre = viewModel.item.genres?.first {
					Text(firstGenre)

					Circle()
						.frame(width: 2, height: 2)
						.padding(.horizontal, 1)
				}

				if let productionYear = viewModel.item.premiereDateFormatted {
					Text(String(productionYear))

					Circle()
						.frame(width: 2, height: 2)
						.padding(.horizontal, 1)
				}

				if let playButtonitem = viewModel.playButtonItem, let runtime = playButtonitem.getItemRuntime() {
					Text(runtime)
				}
			}
			.font(.caption)
			.foregroundColor(Color(UIColor.lightGray))
			.padding(.horizontal)

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
			.padding(.bottom)

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
						Text(viewModel.selectedVideoPlayerViewModel?.versionName ?? L10n.noTitle)
							.fontWeight(.semibold)
							.fixedSize()
						Image(systemName: "chevron.down")
					}
				}
				.padding(.bottom)
			}

			if let playButtonOverview = viewModel.playButtonItem?.overview {
				TruncatedTextView(playButtonOverview,
				                  lineLimit: 3,
				                  font: UIFont.preferredFont(forTextStyle: .footnote)) {
					itemRouter.route(to: \.itemOverview, viewModel.item)
				}
				.foregroundColor(.white)
			} else if let seriesOverview = viewModel.item.overview {
				TruncatedTextView(seriesOverview,
				                  lineLimit: 3,
				                  font: UIFont.preferredFont(forTextStyle: .footnote)) {
					itemRouter.route(to: \.itemOverview, viewModel.item)
				}
				.foregroundColor(.white)
			}

			HStack {
				if let officialRating = viewModel.item.officialRating {
					Text(officialRating)
						.font(.caption)
						.fontWeight(.semibold)
						.lineLimit(1)
						.padding(EdgeInsets(top: 1, leading: 4, bottom: 1, trailing: 4))
						.overlay(RoundedRectangle(cornerRadius: 2)
							.stroke(Color(UIColor.lightGray), lineWidth: 1))
				}

				if let selectedPlayerViewModel = viewModel.selectedVideoPlayerViewModel {
					if !selectedPlayerViewModel.subtitleStreams.isEmpty {
						Text("CC")
							.font(.caption)
							.fontWeight(.semibold)
							.padding(EdgeInsets(top: 1, leading: 4, bottom: 1, trailing: 4))
							.overlay(RoundedRectangle(cornerRadius: 2)
								.stroke(Color(UIColor.lightGray), lineWidth: 1))
					}
				}

				Spacer()
			}
			.foregroundColor(Color(UIColor.lightGray))
		}
		.padding()
		.background {
			BlurView(style: .systemThinMaterialDark)
				.mask {
					LinearGradient(gradient: Gradient(stops: [
						.init(color: .white, location: 0),
						.init(color: .white, location: 0.2),
						.init(color: .white.opacity(0), location: 1),
					]), startPoint: .bottom, endPoint: .top)
				}
		}
	}
}
