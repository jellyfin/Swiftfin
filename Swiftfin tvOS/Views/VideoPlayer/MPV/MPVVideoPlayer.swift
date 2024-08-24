//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI
import VLCUI

struct MPVVideoPlayer: View {

    enum OverlayType {
        case chapters
        case confirmClose
        case main
        case smallMenu
    }

    @Environment(\.scenePhase)
    private var scenePhase

    @EnvironmentObject
    private var router: VideoPlayerCoordinator.Router

    @ObservedObject
    var coordinator = MPVMetalPlayerView.Coordinator()

    @ObservedObject
    private var currentProgressHandler: VideoPlayerManager.CurrentProgressHandler
    @ObservedObject
    private var videoPlayerManager: VideoPlayerManager

    @State
    private var isPresentingOverlay: Bool = false
    @State
    private var isScrubbing: Bool = false

    @ViewBuilder
    private var playerView: some View {
        ZStack {
            MPVMetalPlayerView(coordinator: coordinator)
                .play(videoPlayerManager.currentViewModel.vlcVideoPlayerConfiguration.url)
//                .onPropertyChange{ player, propertyName, propertyData in
//                    switch propertyName {
//                    case MPVProperty.pausedForCache:
//                        loading = propertyData as! Bool
//                    default: break
//                    }
//                }
                .onExitCommand {
                    coordinator.player?.end()
                    router.dismissCoordinator()
                }

            VideoPlayer.Overlay()
                .eraseToAnyView()
                .environmentObject(videoPlayerManager)
                .environmentObject(videoPlayerManager.currentProgressHandler)
                .environmentObject(videoPlayerManager.currentViewModel!)
                .environmentObject(videoPlayerManager.proxy)
                .environment(\.isPresentingOverlay, $isPresentingOverlay)
                .environment(\.isScrubbing, $isScrubbing)
        }
        .onChange(of: videoPlayerManager.currentProgressHandler.scrubbedProgress) { _, newValue in
            guard !newValue.isNaN && !newValue.isInfinite else {
                return
            }
            DispatchQueue.main.async {
                videoPlayerManager.currentProgressHandler
                    .scrubbedSeconds = Int(CGFloat(videoPlayerManager.currentViewModel.item.runTimeSeconds) * newValue)
            }
        }
    }

    @ViewBuilder
    private var loadingView: some View {
        Text("Retrieving media information")
    }

    var body: some View {
        ZStack {

            Color.black

            if let _ = videoPlayerManager.currentViewModel {
                playerView
            } else {
                loadingView
            }
        }
        .ignoresSafeArea()
        .onChange(of: isScrubbing) { _, newValue in
            guard !newValue else { return }
            videoPlayerManager.proxy.setTime(.seconds(currentProgressHandler.scrubbedSeconds))
        }
        .onScenePhase(.active) {
            if Defaults[.VideoPlayer.Transition.playOnActive] {
                videoPlayerManager.proxy.play()
            }
        }
        .onScenePhase(.background) {
            if Defaults[.VideoPlayer.Transition.pauseOnBackground] {
                videoPlayerManager.proxy.pause()
            }
        }
    }
}

extension MPVVideoPlayer {

    init(manager: VideoPlayerManager) {
        self.init(
            currentProgressHandler: manager.currentProgressHandler,
            videoPlayerManager: manager
        )
    }
}
