//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import MediaPlayer
import Stinsen
import SwiftUI
import VLCUI

struct ItemVideoPlayer: View {

    enum OverlayType {
        case main
        case chapters
    }

    @Default(.VideoPlayer.jumpBackwardLength)
    private var jumpBackwardLength
    @Default(.VideoPlayer.jumpForwardLength)
    private var jumpForwardLength
    @Default(.VideoPlayer.Subtitle.subtitleFontName)
    private var subtitleFontName
    @Default(.VideoPlayer.Subtitle.subtitleSize)
    private var subtitleSize

    @EnvironmentObject
    private var router: ItemVideoPlayerCoordinator.Router

    @ObservedObject
    private var currentPlaybackInformation: VideoPlayerManager.CurrentPlaybackInformation = .init()
    @ObservedObject
    private var flashContentProxy: FlashContentProxy = .init()
    @ObservedObject
    private var overlayTimer: TimerProxy = .init()
    @ObservedObject
    private var videoPlayerManager: VideoPlayerManager

    @State
    private var aspectFilled: Bool = false
    @State
    private var currentOverlayType: OverlayType?
    @State
    private var isScrubbing: Bool = false
    @State
    private var presentingPlaybackSettings: Bool = false
    @State
    private var scrubbedProgress: CGFloat = 0

    init(manager: VideoPlayerManager) {
        self.videoPlayerManager = manager
    }

    @ViewBuilder
    private func playerView(with viewModel: VideoPlayerViewModel) -> some View {
        HStack(spacing: 0) {
            ZStack {
                VLCVideoPlayer(configuration: viewModel.configuration)
                    .proxy(videoPlayerManager.proxy)
                    .onTicksUpdated {
                        videoPlayerManager.onTicksUpdated(ticks: $0, playbackInformation: $1)
                        
                        guard !isScrubbing else { return }
                        currentPlaybackInformation.onTicksUpdated(ticks: $0, playbackInformation: $1)
                    }
                    .onStateUpdated(videoPlayerManager.onStateUpdated(state:playbackInformation:))

                GestureView()
                    .onPinch { state, scale in
                        guard state == .began || state == .changed else { return }
                        if scale > 1, !aspectFilled {
                            aspectFilled = true
                            UIView.animate(withDuration: 0.2) {
                                videoPlayerManager.proxy.aspectFill(1)
                            }
                        } else if scale < 1, aspectFilled {
                            aspectFilled = false
                            UIView.animate(withDuration: 0.2) {
                                videoPlayerManager.proxy.aspectFill(0)
                            }
                        }
                    }
                    .onTap { unit, taps in
                        if currentOverlayType == nil {
                            currentOverlayType = .main
                        } else {
                            currentOverlayType = nil
                        }
                    }
                    .onHorizontalSwipe(translation: 100, velocity: 2000) { translation in
                        if translation > 0 {
                            videoPlayerManager.proxy.jumpForward(Int(jumpForwardLength.rawValue))
                            flashContentProxy.flash(interval: 0.5) {
                                Image(systemName: jumpForwardLength.forwardImageLabel)
                                    .font(.system(size: 48, weight: .regular, design: .default))
                                    .foregroundColor(.white)
                            }
                        } else {
                            videoPlayerManager.proxy.jumpBackward(Int(jumpBackwardLength.rawValue))
                            flashContentProxy.flash(interval: 0.5) {
                                Image(systemName: jumpBackwardLength.backwardImageLabel)
                                    .font(.system(size: 48, weight: .regular, design: .default))
                                    .foregroundColor(.white)
                            }
                        }
                    }

                Group {
                    switch currentOverlayType {
                    case .main:
                        Overlay()
                    case .chapters:
                        Overlay.ChapterOverlay()
                    case .none:
                        EmptyView()
                    }
                }
                .transition(.opacity)
                .environmentObject(currentPlaybackInformation)
                .environmentObject(flashContentProxy)
                .environmentObject(overlayTimer)
                .environmentObject(videoPlayerManager)
                .environmentObject(videoPlayerManager.proxy)
                .environmentObject(viewModel)
                .environment(\.aspectFilled, $aspectFilled)
                .environment(\.currentOverlayType, $currentOverlayType)
                .environment(\.isScrubbing, $isScrubbing)
                .environment(\.presentingPlaybackSettings, $presentingPlaybackSettings)
                .environment(\.scrubbedProgress, $scrubbedProgress)

                FlashContentView(proxy: flashContentProxy)
            }
            .onTapGesture {
                overlayTimer.start(5)
            }

            if presentingPlaybackSettings {
                WrappedView {
                    NavigationViewCoordinator(PlaybackSettingsCoordinator()).view()
                }
                .cornerRadius(20, corners: [.topLeft, .bottomLeft])
                .frame(width: 400)
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .trailing)))
                .environmentObject(currentPlaybackInformation)
                .environmentObject(viewModel)
                .environmentObject(videoPlayerManager)
                .environment(\.presentingPlaybackSettings, $presentingPlaybackSettings)
            }
        }
        .animation(.easeIn(duration: 0.2), value: presentingPlaybackSettings)
        .animation(.linear(duration: 0.1), value: currentOverlayType)
        .onChange(of: overlayTimer.isActive) { newValue in
            guard !newValue else { return }
            currentOverlayType = nil
        }
    }

    // TODO: Better and localize
    @ViewBuilder
    private var loadingView: some View {
        ZStack {
            Color.black

            VStack {
                ProgressView()

                Button {
                    router.dismissCoordinator()
                } label: {
                    Text("Cancel")
                        .foregroundColor(.red)
                }
            }
        }
    }

    var body: some View {
        Group {
            if let viewModel = videoPlayerManager.currentViewModel {
                playerView(with: viewModel)
            } else {
                loadingView
            }
        }
        .navigationBarHidden(true)
        .statusBar(hidden: true)
        .ignoresSafeArea()
        .onChange(of: subtitleFontName) { newValue in
            videoPlayerManager.proxy.setSubtitleFont(newValue)
        }
        .onChange(of: subtitleSize) { newValue in
            videoPlayerManager.proxy.setSubtitleSize(.absolute(24 - newValue))
        }
        .onChange(of: videoPlayerManager.currentViewModel) { newValue in
            guard newValue != nil else { return }
            aspectFilled = false
        }
    }
}
