//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct iPadOSLandscapeOverlayView: View {

	@EnvironmentObject
	var itemRouter: ItemCoordinator.Router
	@ObservedObject
	private var viewModel: ItemViewModel

	init(viewModel: ItemViewModel) {
		self.viewModel = viewModel
	}

	@ViewBuilder
	private var firstRow: some View {
		HStack(alignment: .bottom) {

			VStack(alignment: .leading) {

				ImageView(viewModel.item.getLogoImage(maxWidth: 400),
				          resizingMode: .aspectFit,
				          failureView: {
				          	Text(viewModel.item.displayName)
				          		.font(.largeTitle)
				          		.fontWeight(.semibold)
				          		.multilineTextAlignment(.center)
				          		.foregroundColor(.white)
				          		.frame(alignment: .bottom)
				          })
				          .frame(maxWidth: 400, maxHeight: 100)

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
			}

			Spacer()

			Button {
				if let selectedVideoPlayerViewModel = viewModel.selectedVideoPlayerViewModel {
					itemRouter.route(to: \.videoPlayer, selectedVideoPlayerViewModel)
				} else {
					LogManager.log.error("Attempted to play item but no playback information available")
				}
			} label: {
				ZStack {
					Rectangle()
						.foregroundColor(Color(UIColor.systemPurple))
						.frame(maxWidth: 250)
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

	@ViewBuilder
	private var secondRow: some View {
		VStack(alignment: .leading) {
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
	}

	var body: some View {
		VStack {
			firstRow

			RoundedRectangle(cornerRadius: 1)
				.frame(height: 1)
				.foregroundColor(Color(UIColor.lightGray))
				.opacity(0.5)
				.padding(.vertical)

			secondRow
		}
		.padding()
		.padding(.top, 200)
		.background {
			BlurView()
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
