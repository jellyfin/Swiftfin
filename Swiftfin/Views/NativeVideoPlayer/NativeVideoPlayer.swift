//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

// TODO: loading view during `loadingItem` state

struct NativeVideoPlayer: View {

    @EnvironmentObject
    private var router: VideoPlayerCoordinator.Router

    @StateObject
    private var manager: MediaPlayerManager

    init(manager: MediaPlayerManager) {
        self._manager = StateObject(wrappedValue: manager)
    }

    var body: some View {
        NativeVideoPlayerView(manager: manager)
            .navigationBarHidden()
            .statusBarHidden()
            .ignoresSafeArea()
    }
}

struct NativeVideoPlayerView: UIViewControllerRepresentable {

    let manager: MediaPlayerManager

    func makeUIViewController(context: Context) -> UINativeVideoPlayerViewController {
        UINativeVideoPlayerViewController(manager: manager)
    }

    func updateUIViewController(_ uiViewController: UINativeVideoPlayerViewController, context: Context) {}
}
