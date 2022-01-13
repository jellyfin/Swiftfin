//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct PortraitHeaderOverlayView: View {

	@EnvironmentObject
	var itemRouter: ItemCoordinator.Router
	@EnvironmentObject
	private var viewModel: ItemViewModel
	@State
	private var playButtonText: String = ""

	var body: some View {
		VStack(alignment: .leading) {
			HStack(alignment: .bottom, spacing: 12) {

				// MARK: Portrait Image

				ImageView(src: viewModel.item.portraitHeaderViewURL(maxWidth: 130))
					.portraitPoster(width: 130)

				VStack(alignment: .leading, spacing: 1) {
					Spacer()

					// MARK: Name

					Text(viewModel.getItemDisplayName())
						.font(.title2)
						.fontWeight(.semibold)
						.foregroundColor(.primary)
						.fixedSize(horizontal: false, vertical: true)
						.padding(.bottom, 10)

					// MARK: Details

					HStack {
						if viewModel.item.unaired {
							if let premiereDateLabel = viewModel.item.airDateLabel {
								Text(premiereDateLabel)
									.font(.subheadline)
									.fontWeight(.medium)
									.foregroundColor(.secondary)
									.lineLimit(1)
							}
						}

						if viewModel.shouldDisplayRuntime() {
							if let runtime = viewModel.item.getItemRuntime() {
								Text(runtime)
									.font(.subheadline)
									.fontWeight(.medium)
									.foregroundColor(.secondary)
									.lineLimit(1)
							}
						}

						if let productionYear = viewModel.item.productionYear {
							Text(String(productionYear))
								.font(.subheadline)
								.fontWeight(.medium)
								.foregroundColor(.secondary)
								.lineLimit(1)
						}

						if let officialRating = viewModel.item.officialRating {
							Text(officialRating)
								.font(.subheadline)
								.fontWeight(.semibold)
								.foregroundColor(.secondary)
								.lineLimit(1)
								.padding(EdgeInsets(top: 1, leading: 4, bottom: 1, trailing: 4))
								.overlay(RoundedRectangle(cornerRadius: 2)
									.stroke(Color.secondary, lineWidth: 1))
						}
					}

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
					}
				}
				.padding(.bottom, UIDevice.current.userInterfaceIdiom == .pad ? 98 : 30)
			}

			HStack {

				// MARK: Play

				Button {
					if let selectedVideoPlayerViewModel = viewModel.selectedVideoPlayerViewModel {
						itemRouter.route(to: \.videoPlayer, selectedVideoPlayerViewModel)
					} else {
						LogManager.shared.log.error("Attempted to play item but no playback information available")
					}
				} label: {
					HStack {
						Image(systemName: "play.fill")
							.foregroundColor(viewModel.playButtonItem == nil ? Color(UIColor.secondaryLabel) : Color.white)
							.font(.system(size: 20))
						Text(playButtonText)
							.foregroundColor(viewModel.playButtonItem == nil ? Color(UIColor.secondaryLabel) : Color.white)
							.font(.callout)
							.fontWeight(.semibold)
					}
					.frame(width: 130, height: 40)
					.background(viewModel.playButtonItem == nil ? Color(UIColor.secondarySystemFill) : Color.jellyfinPurple)
					.cornerRadius(10)
				}
				.disabled(viewModel.playButtonItem == nil || viewModel.selectedVideoPlayerViewModel == nil)
				.contextMenu {
					if viewModel.playButtonItem != nil, viewModel.item.userData?.playbackPositionTicks ?? 0 > 0 {
						Button {
							if let selectedVideoPlayerViewModel = viewModel.selectedVideoPlayerViewModel {
								selectedVideoPlayerViewModel.injectCustomValues(startFromBeginning: true)
								itemRouter.route(to: \.videoPlayer, selectedVideoPlayerViewModel)
							} else {
								LogManager.shared.log.error("Attempted to play item but no playback information available")
							}
						} label: {
							Label(L10n.playFromBeginning, systemImage: "gobackward")
						}
					}
				}

				Spacer()

				if viewModel.item.itemType.showDetails {
					// MARK: Favorite

					Button {
						viewModel.updateFavoriteState()
					} label: {
						if viewModel.isFavorited {
							Image(systemName: "heart.fill")
								.foregroundColor(Color(UIColor.systemRed))
								.font(.system(size: 20))
						} else {
							Image(systemName: "heart")
								.foregroundColor(Color.primary)
								.font(.system(size: 20))
						}
					}
					.disabled(viewModel.isLoading)

					// MARK: Watched

					Button {
						viewModel.updateWatchState()
					} label: {
						if viewModel.isWatched {
							Image(systemName: "checkmark.circle.fill")
								.foregroundColor(Color.jellyfinPurple)
								.font(.system(size: 20))
						} else {
							Image(systemName: "checkmark.circle")
								.foregroundColor(Color.primary)
								.font(.system(size: 20))
						}
					}
					.disabled(viewModel.isLoading)
				}
			}.padding(.top, 8)
		}
		.onAppear {
			playButtonText = viewModel.playButtonText()
		}
		.padding(.horizontal)
		.padding(.bottom, UIDevice.current.userInterfaceIdiom == .pad ? -189 : -64)
	}
}
