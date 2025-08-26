//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import AVKit
import JellyfinAPI
import Logging
import SwiftUI

// TODO: loading view during `loadingItem` state
// TODO: error state

struct NativeVideoPlayer: View {

    // TODO: remove
    @EnvironmentObject
    private var scrubbedSecondsBox: PublishedBox<Duration>

    @LazyState
    private var proxy: AVMediaPlayerProxy

    @ObservedObject
    private var manager: MediaPlayerManager

    init(
        manager: MediaPlayerManager
    ) {
        self.manager = manager
        self._proxy = .init(wrappedValue: {
            let proxy = AVMediaPlayerProxy()
            manager.proxy = proxy
            return proxy
        }())
    }

    var body: some View {
        switch manager.state {
        case .loadingItem:
            ProgressView()
        case let .error(error):
            Text(error.localizedDescription)
        default:
            NativeVideoPlayerView(proxy: proxy)
        }
    }
}

extension NativeVideoPlayer {

    private struct NativeVideoPlayerView: UIViewControllerRepresentable {

        let proxy: AVMediaPlayerProxy

        func makeUIViewController(context: Context) -> UINativeVideoPlayerViewController {
            UINativeVideoPlayerViewController(proxy: proxy)
        }

        func updateUIViewController(_ uiViewController: UINativeVideoPlayerViewController, context: Context) {}
    }

    private class UINativeVideoPlayerViewController: AVPlayerViewController {

        private let proxy: AVMediaPlayerProxy

        init(proxy: AVMediaPlayerProxy) {
            self.proxy = proxy

            super.init(nibName: nil, bundle: nil)

            player = proxy.player

            player?.allowsExternalPlayback = true
            player?.appliesMediaSelectionCriteriaAutomatically = false
            allowsPictureInPicturePlayback = true

            #if !os(tvOS)
            updatesNowPlayingInfoCenter = false
            #endif
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
