//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
import JellyfinAPI
import MobileVLCKit
import Sliders
import SwiftUI

struct VLCPlayerOverlayView: View {
	@ObservedObject
	var viewModel: VideoPlayerViewModel

	@ViewBuilder
	private var mainButtonView: some View {
		if viewModel.overlayType == .normal {
			switch viewModel.playerState {
			case .stopped, .paused:
				Image(systemName: "play.fill")
					.font(.system(size: 56, weight: .semibold, design: .default))
			case .playing:
				Image(systemName: "pause")
					.font(.system(size: 56, weight: .semibold, design: .default))
			default:
				ProgressView()
					.scaleEffect(2)
			}
		} else if viewModel.overlayType == .compact {
			switch viewModel.playerState {
			case .stopped, .paused:
				Image(systemName: "play.fill")
					.font(.system(size: 28, weight: .heavy, design: .default))
			case .playing:
				Image(systemName: "pause")
					.font(.system(size: 28, weight: .heavy, design: .default))
			default:
				ProgressView()
			}
		}
	}

	@ViewBuilder
	private var mainBody: some View {
		VStack {
			// MARK: Top Bar

			ZStack(alignment: .top) {
				if viewModel.overlayType == .compact {
					LinearGradient(gradient: Gradient(colors: [.black.opacity(0.8), .clear]),
					               startPoint: .top,
					               endPoint: .bottom)
						.ignoresSafeArea()
						.frame(height: 70)
				}

				VStack(alignment: .EpisodeSeriesAlignmentGuide) {
					HStack(alignment: .center) {
						HStack {
							Button {
								viewModel.playerOverlayDelegate?.didSelectClose()
							} label: {
								Image(systemName: "chevron.backward")
									.padding()
									.padding(.trailing, -10)
							}

							Text(viewModel.title)
								.font(.title3)
								.fontWeight(.bold)
								.lineLimit(1)
								.alignmentGuide(.EpisodeSeriesAlignmentGuide) { context in
									context[.leading]
								}
						}

						Spacer()

						HStack(spacing: 20) {
							// MARK: Previous Item

							if viewModel.shouldShowPlayPreviousItem {
								Button {
									viewModel.playerOverlayDelegate?.didSelectPlayPreviousItem()
								} label: {
									Image(systemName: "chevron.left.circle")
								}
								.disabled(viewModel.previousItemVideoPlayerViewModel == nil)
								.foregroundColor(viewModel.nextItemVideoPlayerViewModel == nil ? .gray : .white)
							}

							// MARK: Next Item

							if viewModel.shouldShowPlayNextItem {
								Button {
									viewModel.playerOverlayDelegate?.didSelectPlayNextItem()
								} label: {
									Image(systemName: "chevron.right.circle")
								}
								.disabled(viewModel.nextItemVideoPlayerViewModel == nil)
								.foregroundColor(viewModel.nextItemVideoPlayerViewModel == nil ? .gray : .white)
							}

							// MARK: Autoplay

							if viewModel.shouldShowAutoPlay {
								Button {
									viewModel.autoplayEnabled.toggle()
								} label: {
									if viewModel.autoplayEnabled {
										Image(systemName: "play.circle.fill")
									} else {
										Image(systemName: "stop.circle")
									}
								}
							}

							// MARK: Subtitle Toggle

							if !viewModel.subtitleStreams.isEmpty {
								Button {
									viewModel.subtitlesEnabled.toggle()
								} label: {
									if viewModel.subtitlesEnabled {
										Image(systemName: "captions.bubble.fill")
									} else {
										Image(systemName: "captions.bubble")
									}
								}
								.disabled(viewModel.selectedSubtitleStreamIndex == -1)
								.foregroundColor(viewModel.selectedSubtitleStreamIndex == -1 ? .gray : .white)
							}

							// MARK: Screen Fill

							Button {
								viewModel.playerOverlayDelegate?.didSelectScreenFill()
							} label: {
								if viewModel.playerOverlayDelegate?.getScreenFilled() ?? true {
									if viewModel.playerOverlayDelegate?.isVideoAspectRatioGreater() ?? true {
										Image(systemName: "rectangle.arrowtriangle.2.inward")
									} else {
										Image(systemName: "rectangle.portrait.arrowtriangle.2.inward")
									}
								} else {
									if viewModel.playerOverlayDelegate?.isVideoAspectRatioGreater() ?? true {
										Image(systemName: "rectangle.arrowtriangle.2.outward")
									} else {
										Image(systemName: "rectangle.portrait.arrowtriangle.2.outward")
									}
								}
							}

							// MARK: Settings Menu

							Menu {
								// MARK: Audio Streams

								Menu {
									ForEach(viewModel.audioStreams, id: \.self) { audioStream in
										Button {
											viewModel.selectedAudioStreamIndex = audioStream.index ?? -1
										} label: {
											if audioStream.index == viewModel.selectedAudioStreamIndex {
												Label(audioStream.displayTitle ?? L10n.noTitle, systemImage: "checkmark")
											} else {
												Text(audioStream.displayTitle ?? L10n.noTitle)
											}
										}
									}
								} label: {
									HStack {
										Image(systemName: "speaker.wave.3")
										L10n.audio.text
									}
								}

								// MARK: Subtitle Streams

								Menu {
									ForEach(viewModel.subtitleStreams, id: \.self) { subtitleStream in
										Button {
											viewModel.selectedSubtitleStreamIndex = subtitleStream.index ?? -1
										} label: {
											if subtitleStream.index == viewModel.selectedSubtitleStreamIndex {
												Label(subtitleStream.displayTitle ?? L10n.noTitle, systemImage: "checkmark")
											} else {
												Text(subtitleStream.displayTitle ?? L10n.noTitle)
											}
										}
									}
								} label: {
									HStack {
										Image(systemName: "captions.bubble")
										L10n.subtitles.text
									}
								}

								// MARK: Playback Speed

								Menu {
									ForEach(PlaybackSpeed.allCases, id: \.self) { speed in
										Button {
											viewModel.playbackSpeed = speed
										} label: {
											if speed == viewModel.playbackSpeed {
												Label(speed.displayTitle, systemImage: "checkmark")
											} else {
												Text(speed.displayTitle)
											}
										}
									}
								} label: {
									HStack {
										Image(systemName: "speedometer")
										L10n.playbackSpeed.text
									}
								}

								// MARK: Chapters

								if !viewModel.chapters.isEmpty {
									Button {
										viewModel.playerOverlayDelegate?.didSelectChapters()
									} label: {
										HStack {
											Image(systemName: "list.dash")
											L10n.chapters.text
										}
									}
								}

								// MARK: Jump Button Lengths

								if viewModel.shouldShowJumpButtonsInOverlayMenu {
									Menu {
										ForEach(VideoPlayerJumpLength.allCases, id: \.self) { forwardLength in
											Button {
												viewModel.jumpForwardLength = forwardLength
											} label: {
												if forwardLength == viewModel.jumpForwardLength {
													Label(forwardLength.shortLabel, systemImage: "checkmark")
												} else {
													Text(forwardLength.shortLabel)
												}
											}
										}
									} label: {
										HStack {
											Image(systemName: "goforward")
											L10n.jumpForwardLength.text
										}
									}

									Menu {
										ForEach(VideoPlayerJumpLength.allCases, id: \.self) { backwardLength in
											Button {
												viewModel.jumpBackwardLength = backwardLength
											} label: {
												if backwardLength == viewModel.jumpBackwardLength {
													Label(backwardLength.shortLabel, systemImage: "checkmark")
												} else {
													Text(backwardLength.shortLabel)
												}
											}
										}
									} label: {
										HStack {
											Image(systemName: "gobackward")
											L10n.jumpBackwardLength.text
										}
									}
								}
							} label: {
								Image(systemName: "ellipsis.circle")
							}
						}
					}
					.font(.system(size: 24))
					.frame(height: 50)

					if let seriesTitle = viewModel.subtitle {
						Text(seriesTitle)
							.font(.subheadline)
							.foregroundColor(Color.gray)
							.alignmentGuide(.EpisodeSeriesAlignmentGuide) { context in
								context[.leading]
							}
							.offset(y: -18)
					}
				}
				.padding(.horizontal, UIDevice.current.userInterfaceIdiom == .pad ? 30 : 0)
			}

			// MARK: Center

			Spacer()

			if viewModel.overlayType == .normal {
				HStack(spacing: 80) {
					Button {
						viewModel.playerOverlayDelegate?.didSelectBackward()
					} label: {
						Image(systemName: viewModel.jumpBackwardLength.backwardImageLabel)
					}

					Button {
						viewModel.playerOverlayDelegate?.didSelectMain()
					} label: {
						mainButtonView
					}
					.frame(width: 200)

					Button {
						viewModel.playerOverlayDelegate?.didSelectForward()
					} label: {
						Image(systemName: viewModel.jumpForwardLength.forwardImageLabel)
					}
				}
				.font(.system(size: 48))
			}

			Spacer()

			// MARK: Bottom Bar

			ZStack(alignment: .center) {
				if viewModel.overlayType == .compact {
					LinearGradient(gradient: Gradient(colors: [.clear, .black.opacity(0.8)]),
					               startPoint: .top,
					               endPoint: .bottom)
						.ignoresSafeArea()
						.frame(height: 70)
				}

				HStack {
					if viewModel.overlayType == .compact {
						HStack {
							Button {
								viewModel.playerOverlayDelegate?.didSelectBackward()
							} label: {
								Image(systemName: viewModel.jumpBackwardLength.backwardImageLabel)
									.padding(.horizontal, 5)
							}

							Button {
								viewModel.playerOverlayDelegate?.didSelectMain()
							} label: {
								mainButtonView
									.frame(minWidth: 30, maxWidth: 30)
									.padding(.horizontal, 10)
							}

							Button {
								viewModel.playerOverlayDelegate?.didSelectForward()
							} label: {
								Image(systemName: viewModel.jumpForwardLength.forwardImageLabel)
									.padding(.horizontal, 5)
							}
						}
						.font(.system(size: 24, weight: .semibold, design: .default))
					}

					Text(viewModel.leftLabelText)
						.font(.system(size: 18, weight: .semibold, design: .default))
						.frame(minWidth: 70, maxWidth: 70)
						.accessibilityLabel(L10n.currentPosition)
						.accessibilityValue(viewModel.leftLabelText)

					ValueSlider(value: $viewModel.sliderPercentage, onEditingChanged: { editing in
						viewModel.sliderIsScrubbing = editing
					})
						.valueSliderStyle(HorizontalValueSliderStyle(track:
							HorizontalValueTrack(view:
								Capsule().foregroundColor(.purple))
								.background(Capsule().foregroundColor(Color.gray.opacity(0.25)))
								.frame(height: 4),
							thumb: Circle().foregroundColor(.purple),
							thumbSize: CGSize.Circle(radius: viewModel.sliderIsScrubbing ? 20 : 15),
							thumbInteractiveSize: CGSize.Circle(radius: 40),
							options: .defaultOptions))
						.frame(maxHeight: 50)

					Text(viewModel.rightLabelText)
						.font(.system(size: 18, weight: .semibold, design: .default))
						.frame(minWidth: 70, maxWidth: 70)
						.accessibilityLabel(L10n.remainingTime)
						.accessibilityValue(viewModel.rightLabelText)
				}
				.padding(.horizontal, UIDevice.current.userInterfaceIdiom == .pad ? 30 : 0)
				.padding(.bottom, UIDevice.current.userInterfaceIdiom == .pad ? 10 : 0)
			}
		}
		.tint(Color.white)
		.foregroundColor(Color.white)
	}

	var body: some View {
		if viewModel.overlayType == .normal {
			mainBody
				.contentShape(Rectangle())
				.onTapGesture {
					viewModel.playerOverlayDelegate?.didGenerallyTap()
				}
				.background {
					Color(uiColor: .black.withAlphaComponent(0.5))
						.ignoresSafeArea()
				}
		} else {
			mainBody
				.contentShape(Rectangle())
				.onTapGesture {
					viewModel.playerOverlayDelegate?.didGenerallyTap()
				}
		}
	}
}

struct VLCPlayerCompactOverlayView_Previews: PreviewProvider {
	static let videoPlayerViewModel = VideoPlayerViewModel(item: BaseItemDto(),
	                                                       title: "Glorious Purpose",
	                                                       subtitle: "Loki - S1E1",
	                                                       directStreamURL: URL(string: "www.apple.com")!,
	                                                       transcodedStreamURL: nil,
	                                                       hlsStreamURL: URL(string: "www.apple.com")!,
	                                                       streamType: .direct,
	                                                       response: PlaybackInfoResponse(),
	                                                       audioStreams: [MediaStream(displayTitle: "English", index: -1)],
	                                                       subtitleStreams: [MediaStream(displayTitle: "None", index: -1)],
	                                                       chapters: [],
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

			VLCPlayerOverlayView(viewModel: videoPlayerViewModel)
		}
		.previewInterfaceOrientation(.landscapeLeft)
	}
}

// MARK: TitleSubtitleAlignment

extension HorizontalAlignment {
	private struct TitleSubtitleAlignment: AlignmentID {
		static func defaultValue(in context: ViewDimensions) -> CGFloat {
			context[HorizontalAlignment.leading]
		}
	}

	static let EpisodeSeriesAlignmentGuide = HorizontalAlignment(TitleSubtitleAlignment.self)
}
