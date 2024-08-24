//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import MediaPlayer
import Stinsen
import SwiftUI
import VLCUI

// TODO: organize
// TODO: localization necessary for toast text?
// TODO: entire gesture layer should be separate

struct VideoPlayer: View {

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
    @Default(.VideoPlayer.Gesture.multiTapGesture)
    private var multiTapGesture
    @Default(.VideoPlayer.Gesture.doubleTouchGesture)
    private var doubleTouchGesture
    @Default(.VideoPlayer.Gesture.pinchGesture)
    private var pinchGesture
    @Default(.VideoPlayer.Gesture.verticalPanGestureLeft)
    private var verticalGestureLeft
    @Default(.VideoPlayer.Gesture.verticalPanGestureRight)
    private var verticalGestureRight

    @Default(.VideoPlayer.Subtitle.subtitleColor)
    private var subtitleColor
    @Default(.VideoPlayer.Subtitle.subtitleFontName)
    private var subtitleFontName
    @Default(.VideoPlayer.Subtitle.subtitleSize)
    private var subtitleSize

    @Environment(\.scenePhase)
    private var scenePhase
    
    @EnvironmentObject
    private var router: VideoPlayerCoordinator.Router

    @State
    private var audioOffset: Int = 0
    @State
    private var isAspectFilled: Bool = false
    @State
    private var isGestureLocked: Bool = false
    @State
    private var isPresentingOverlay: Bool = false
    @State
    private var isScrubbing: Bool = false
    @State
    private var playbackSpeed: Double = 1
    @State
    private var subtitleOffset: Int = 0

    @StateObject
    private var manager: VideoPlayerManager
    @StateObject
    private var vlcUIProxy: VLCVideoPlayer.Proxy

    private let gestureStateHandler: GestureStateHandler = .init()
    private let updateViewProxy: UpdateViewProxy = .init()

    @ViewBuilder
    private var playerView: some View {
        ZStack {
            VLCVideoPlayer(configuration: manager.currentItem!.vlcConfiguration)
//                .proxy(vlcUIProxy)
                    .onTicksUpdated { _, _ in

//                    let newSeconds = ticks / 1000
//                    let newProgress = CGFloat(newSeconds) / CGFloat(videoPlayerManager.currentViewModel.item.runTimeSeconds)
//                    currentProgressHandler.progress = newProgress
//                    currentProgressHandler.seconds = newSeconds
//
//                    guard !isScrubbing else { return }
//                    currentProgressHandler.scrubbedProgress = newProgress
//
//                    videoPlayerManager.onTicksUpdated(
//                        ticks: ticks,
//                        playbackInformation: information
//                    )
                    }
                    .onStateUpdated { state, _ in
                        manager.onStateUpdated(newState: state)
                    }

            VideoPlayer.Overlay()
        }
//        .onChange(of: videoPlayerManager.currentProgressHandler.scrubbedProgress) { newValue in
//            guard !newValue.isNaN && !newValue.isInfinite else {
//                return
//            }
//            DispatchQueue.main.async {
//                videoPlayerManager.currentProgressHandler
//                    .scrubbedSeconds = Int(CGFloat(videoPlayerManager.currentViewModel.item.runTimeSeconds) * newValue)
//            }
//        }
        .overlay(alignment: .top) {
            UpdateView(proxy: updateViewProxy)
                .padding(.top)
        }
        .videoPlayerKeyCommands(
            gestureStateHandler: gestureStateHandler,
            updateViewProxy: updateViewProxy
        )
        .environmentObject(manager)
        .environment(\.aspectFilled, $isAspectFilled)
        .environment(\.isPresentingOverlay, $isPresentingOverlay)
        .environment(\.isScrubbing, $isScrubbing)
        .environment(\.playbackSpeed, $playbackSpeed)
    }

    var body: some View {
        ZStack {
//            if let _ = videoPlayerManager.currentViewModel {
//                playerView
//            } else {
//                LoadingView()
//                    .transition(.opacity)
//            }
        }
        .navigationBarHidden()
        .statusBarHidden()
        .ignoresSafeArea()
//        .onChange(of: audioOffset) { newValue in
//            vlcUIProxy.setAudioDelay(.ticks(newValue))
//        }
//        .onChange(of: isAspectFilled) { newValue in
//            UIView.animate(withDuration: 0.2) {
//                vlcUIProxy.aspectFill(newValue ? 1 : 0)
//            }
//        }
//        .onChange(of: isGestureLocked) { newValue in
//            if newValue {
//                updateViewProxy.present(systemName: "lock.fill", title: "Gestures Locked")
//            } else {
//                updateViewProxy.present(systemName: "lock.open.fill", title: "Gestures Unlocked")
//            }
//        }
//        .onChange(of: isScrubbing) { newValue in
//            guard !newValue else { return }
//            vlcUIProxy.setTime(.seconds(currentProgressHandler.scrubbedSeconds))
//        }
//        .onChange(of: subtitleColor) { newValue in
//            vlcUIProxy.setSubtitleColor(.absolute(newValue.uiColor))
//        }
//        .onChange(of: subtitleFontName) { newValue in
//            vlcUIProxy.setSubtitleFont(newValue)
//        }
//        .onChange(of: subtitleOffset) { newValue in
//            vlcUIProxy.setSubtitleDelay(.ticks(newValue))
//        }
//        .onChange(of: subtitleSize) { newValue in
//            vlcUIProxy.setSubtitleSize(.absolute(24 - newValue))
//        }
//        .onChange(of: videoPlayerManager.currentViewModel) { newViewModel in
//            guard let newViewModel else { return }
//
//            vlcUIProxy.playNewMedia(newViewModel.vlcVideoPlayerConfiguration)
//
//            isAspectFilled = false
//            audioOffset = 0
//            subtitleOffset = 0
//        }
//        .onScenePhase(.active) {
//            if Defaults[.VideoPlayer.Transition.playOnActive] {
//                videoPlayerManager.proxy.play()
//            }
//        }
//        .onScenePhase(.background) {
//            if Defaults[.VideoPlayer.Transition.pauseOnBackground] {
//                videoPlayerManager.proxy.pause()
//            }
//        }
    }
}

extension VideoPlayer {

    init(item: BaseItemDto, mediaSource: MediaSourceInfo) {

        let manager = VideoPlayerManager(item: item, mediaSource: mediaSource)
        let videoPlayerProxy = VLCVideoPlayerProxy()
        let vlcUIProxy = VLCVideoPlayer.Proxy()

        videoPlayerProxy.vlcUIProxy = vlcUIProxy
        manager.proxy = videoPlayerProxy

        self.init(
            manager: manager,
            vlcUIProxy: vlcUIProxy
        )
    }
}
