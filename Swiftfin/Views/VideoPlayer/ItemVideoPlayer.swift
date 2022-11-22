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
    
    @Default(.VideoPlayer.Gesture.horizontalPanGesture)
    private var horizontalPanGesture
    @Default(.VideoPlayer.Gesture.horizontalSwipeGesture)
    private var horizontalSwipeGesture
    @Default(.VideoPlayer.Gesture.longPressGesture)
    private var longPressGesture
    @Default(.VideoPlayer.Gesture.pinchGesture)
    private var pinchGesture
    @Default(.VideoPlayer.Gesture.verticalPanGestureLeft)
    private var verticalGestureLeft
    @Default(.VideoPlayer.Gesture.verticalPanGestureRight)
    private var verticalGestureRight

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
    private var splitContentViewProxy: SplitContentViewProxy = .init()
    @ObservedObject
    private var videoPlayerManager: VideoPlayerManager

    @State
    private var aspectFilled: Bool = false
    @State
    private var audioOffset: Int = 0
    @State
    private var currentOverlayType: OverlayType?
    @State
    private var gestureLocked: Bool = false
    @State
    private var isScrubbing: Bool = false
    @State
    private var scrubbedProgress: CGFloat = 0
    @State
    private var subtitleOffset: Int = 0

    init(manager: VideoPlayerManager) {
        self.videoPlayerManager = manager
    }

    @ViewBuilder
    private func playerView(with viewModel: VideoPlayerViewModel) -> some View {
        SplitContentView()
            .proxy(splitContentViewProxy)
            .content {
                ZStack {
                    VLCVideoPlayer(configuration: viewModel.configuration)
                        .proxy(videoPlayerManager.proxy)
                        .onTicksUpdated {
                            videoPlayerManager.onTicksUpdated(ticks: $0, playbackInformation: $1)
                            currentPlaybackInformation.onTicksUpdated(ticks: $0, playbackInformation: $1)
                        }
                        .onStateUpdated(videoPlayerManager.onStateUpdated(state:playbackInformation:))

                    GestureView()
                        .onHorizontalPan(handleHorizontalPan)
                        .onHorizontalSwipe(translation: 100, velocity: 2000, handleHorizontalSwipe)
                        .onLongPress(minimumDuration: 2, handleLongPress)
                        .onPinch(handlePinchGesture)
                        .onTap(samePointPadding: 20, samePointTimeout: 0.5, handleTapGesture)
                        .onVerticalPan(handleVerticalPan)

                    Group {
                        switch currentOverlayType {
                        case .main:
                            Overlay()
//                        case .chapters:
//                            Overlay.ChapterOverlay()
                        default:
                            EmptyView()
                        }
                    }
                    .transition(.opacity)
                    .environmentObject(currentPlaybackInformation)
                    .environmentObject(flashContentProxy)
                    .environmentObject(overlayTimer)
                    .environmentObject(splitContentViewProxy)
                    .environmentObject(videoPlayerManager)
                    .environmentObject(videoPlayerManager.proxy)
                    .environmentObject(viewModel)
                    .environment(\.aspectFilled, $aspectFilled)
                    .environment(\.currentOverlayType, $currentOverlayType)
                    .environment(\.isScrubbing, $isScrubbing)
                    .environment(\.scrubbedProgress, $scrubbedProgress)

                    FlashContentView(proxy: flashContentProxy)
                        .allowsHitTesting(false)
                }
                .onTapGesture {
                    overlayTimer.start(5)
                }
            }
            .splitContent {
                WrappedView {
                    NavigationViewCoordinator(PlaybackSettingsCoordinator()).view()
                }
                    .cornerRadius(20, corners: [.topLeft, .bottomLeft])
                    .environmentObject(currentPlaybackInformation)
                    .environmentObject(splitContentViewProxy)
                    .environmentObject(viewModel)
                    .environmentObject(videoPlayerManager)
                    .environment(\.audioOffset, $audioOffset)
                    .environment(\.subtitleOffset, $subtitleOffset)
            }
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
        .onChange(of: audioOffset) { newValue in
            videoPlayerManager.proxy.setAudioDelay(.ticks(newValue))
        }
        .onChange(of: gestureLocked) { newValue in
            // TODO: Change
            flashContentProxy.flash(interval: 2) {
                ZStack {
                    Color.black
                        .opacity(0.5)
                    
                    if newValue {
                        Image(systemName: "lock.fill")
                    } else {
                        Image(systemName: "lock.open.fill")
                    }
                }
                .font(.system(size: 36, weight: .regular, design: .default))
            }
        }
        .onChange(of: subtitleFontName) { newValue in
            videoPlayerManager.proxy.setSubtitleFont(newValue)
        }
        .onChange(of: subtitleOffset) { newValue in
            videoPlayerManager.proxy.setSubtitleDelay(.ticks(newValue))
        }
        .onChange(of: subtitleSize) { newValue in
            videoPlayerManager.proxy.setSubtitleSize(.absolute(24 - newValue))
        }
        .onChange(of: videoPlayerManager.currentViewModel) { newViewModel in
            guard let newViewModel else { return }
            
            videoPlayerManager.proxy.playNewMedia(newViewModel.configuration)
            
            aspectFilled = false
            audioOffset = 0
            subtitleOffset = 0
        }
    }
}

// MARK: Gestures

extension ItemVideoPlayer {
    
    private func handleHorizontalPan(
        state: UIGestureRecognizer.State,
        unitPoint: UnitPoint,
        velocity: CGFloat,
        translation: CGFloat
    ) {
        guard !gestureLocked else { return }
        
        switch horizontalPanGesture {
        case .none:
            return
        case .scrub:
            return
        default:
            return
        }
    }
    
    private func handleHorizontalSwipe(
        state: UIGestureRecognizer.State,
        unitPoint: UnitPoint,
        velocity: CGFloat,
        translation: CGFloat
    ) {
        guard !gestureLocked else { return }
        
        switch horizontalSwipeGesture {
        case .none:
            return
        case .jump:
            jumpAction(translation: translation)
        }
    }
    
    private func handleLongPress(point: UnitPoint) {
        switch longPressGesture {
        case .none:
            return
        case .gestureLock:
            guard currentOverlayType == nil else { return }
            gestureLocked.toggle()
        }
    }
    
    private func handlePinchGesture(state: UIGestureRecognizer.State, unitPoint: UnitPoint, scale: CGFloat) {
        guard !gestureLocked else { return }
        
        switch pinchGesture {
        case .none:
            return
        case .aspectFill:
            aspectFillAction(state: state, unitPoint: unitPoint, scale: scale)
        }
    }
    
    private func handleTapGesture(unitPoint: UnitPoint, taps: Int) {
        guard !gestureLocked else { return }
        
        if currentOverlayType == nil {
            currentOverlayType = .main
        } else {
            currentOverlayType = nil
        }
    }
    
    private func handleVerticalPan(
        state: UIGestureRecognizer.State,
        unitPoint: UnitPoint,
        velocity: CGFloat,
        translation: CGFloat
    ) {
        guard !gestureLocked else { return }
    }
}

// MARK: Gesture Actions

extension ItemVideoPlayer {
    
    private func aspectFillAction(state: UIGestureRecognizer.State, unitPoint: UnitPoint, scale: CGFloat) {
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
    
    private func jumpAction(translation: CGFloat) {
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
}
