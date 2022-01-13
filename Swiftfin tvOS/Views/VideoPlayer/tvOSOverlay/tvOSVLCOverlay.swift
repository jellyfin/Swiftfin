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

struct tvOSVLCOverlay: View {

	@ObservedObject
	var viewModel: VideoPlayerViewModel
	@Default(.downActionShowsMenu)
	var downActionShowsMenu

	@ViewBuilder
	private var mainButtonView: some View {
		switch viewModel.playerState {
		case .stopped, .paused:
			Image(systemName: "play.circle")
		case .playing:
			Image(systemName: "pause.circle")
		default:
			ProgressView()
		}
	}

	var body: some View {
		ZStack(alignment: .bottom) {

			LinearGradient(gradient: Gradient(colors: [.clear, .black.opacity(0.8), .black]),
			               startPoint: .top,
			               endPoint: .bottom)
				.ignoresSafeArea()
				.frame(height: viewModel.subtitle == nil ? 180 : 210)

			VStack {

				Spacer()

				HStack(alignment: .bottom) {

					VStack(alignment: .leading) {
						if let subtitle = viewModel.subtitle {
							Text(subtitle)
								.font(.subheadline)
								.foregroundColor(.white)
						}

						Text(viewModel.title)
							.font(.title3)
							.fontWeight(.bold)
					}

					Spacer()

					if viewModel.shouldShowPlayPreviousItem {
						SFSymbolButton(systemName: "chevron.left.circle", action: {
							viewModel.playerOverlayDelegate?.didSelectPlayPreviousItem()
						})
							.frame(maxWidth: 30, maxHeight: 30)
							.disabled(viewModel.previousItemVideoPlayerViewModel == nil)
							.foregroundColor(viewModel.nextItemVideoPlayerViewModel == nil ? .gray : .white)
					}

					if viewModel.shouldShowPlayNextItem {
						SFSymbolButton(systemName: "chevron.right.circle", action: {
							viewModel.playerOverlayDelegate?.didSelectPlayNextItem()
						})
							.frame(maxWidth: 30, maxHeight: 30)
							.disabled(viewModel.nextItemVideoPlayerViewModel == nil)
							.foregroundColor(viewModel.nextItemVideoPlayerViewModel == nil ? .gray : .white)
					}

					if viewModel.shouldShowAutoPlay {
						if viewModel.autoplayEnabled {
							SFSymbolButton(systemName: "play.circle.fill") {
								viewModel.autoplayEnabled.toggle()
							}
							.frame(maxWidth: 30, maxHeight: 30)
						} else {
							SFSymbolButton(systemName: "stop.circle") {
								viewModel.autoplayEnabled.toggle()
							}
							.frame(maxWidth: 30, maxHeight: 30)
						}
					}

					if !viewModel.subtitleStreams.isEmpty {
						if viewModel.subtitlesEnabled {
							SFSymbolButton(systemName: "captions.bubble.fill") {
								viewModel.subtitlesEnabled.toggle()
							}
							.frame(maxWidth: 30, maxHeight: 30)
						} else {
							SFSymbolButton(systemName: "captions.bubble") {
								viewModel.subtitlesEnabled.toggle()
							}
							.frame(maxWidth: 30, maxHeight: 30)
						}
					}

					if !downActionShowsMenu {
						SFSymbolButton(systemName: "ellipsis.circle") {
							viewModel.playerOverlayDelegate?.didSelectMenu()
						}
						.frame(maxWidth: 30, maxHeight: 30)
					}
				}
				.offset(x: 0, y: 10)

				SliderView(viewModel: viewModel)
					.frame(maxHeight: 40)

				HStack {

					HStack(spacing: 10) {
						mainButtonView
							.frame(maxWidth: 40, maxHeight: 40)

						Text(viewModel.leftLabelText)
					}

					Spacer()

					Text(viewModel.rightLabelText)
				}
				.offset(x: 0, y: -10)
			}
		}
		.foregroundColor(.white)
	}
}

struct tvOSVLCOverlay_Previews: PreviewProvider {

	static let videoPlayerViewModel = VideoPlayerViewModel(item: BaseItemDto(),
	                                                       title: "Glorious Purpose",
	                                                       subtitle: "Loki - S1E1",
	                                                       streamURL: URL(string: "www.apple.com")!,
	                                                       streamType: .direct,
	                                                       response: PlaybackInfoResponse(),
	                                                       audioStreams: [MediaStream(displayTitle: "English", index: -1)],
	                                                       subtitleStreams: [MediaStream(displayTitle: "None", index: -1)],
	                                                       selectedAudioStreamIndex: -1,
	                                                       selectedSubtitleStreamIndex: -1,
	                                                       subtitlesEnabled: true,
	                                                       autoplayEnabled: false,
	                                                       overlayType: .compact,
	                                                       shouldShowPlayPreviousItem: true,
	                                                       shouldShowPlayNextItem: true,
	                                                       shouldShowAutoPlay: true,
	                                                       container: "",
	                                                       filename: nil,
	                                                       versionName: nil)

	static var previews: some View {
		ZStack {
			Color.red
				.ignoresSafeArea()

			tvOSVLCOverlay(viewModel: videoPlayerViewModel)
		}
	}
}
