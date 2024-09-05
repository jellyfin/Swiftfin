//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct NativeVideoPlayer: View {

    @EnvironmentObject
    private var router: VideoPlayerCoordinator.Router

    @StateObject
    private var manager: VideoPlayerManager

    init(item: BaseItemDto, mediaSource: MediaSourceInfo) {
        self._manager = StateObject(wrappedValue: VideoPlayerManager(item: item, mediaSource: mediaSource))
    }

    init(item: VideoPlayerPlaybackItem) {
        self._manager = StateObject(wrappedValue: VideoPlayerManager(playbackItem: item))
    }

    var body: some View {
        ZStack {
            if let _ = manager.playbackItem {
                NativeVideoPlayerView(manager: manager)
            } else {
                VideoPlayer.LoadingView()
            }
        }
        .navigationBarHidden()
        .statusBarHidden()
        .ignoresSafeArea()
    }
}

struct NativeVideoPlayerView: UIViewControllerRepresentable {

    let manager: VideoPlayerManager

    func makeUIViewController(context: Context) -> UINativeVideoPlayerViewController {
        UINativeVideoPlayerViewController(manager: manager)
    }

    func updateUIViewController(_ uiViewController: UINativeVideoPlayerViewController, context: Context) {}
}
