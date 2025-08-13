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

struct NativeVideoPlayer: View {

    @Environment(\.isScrubbing)
    private var isScrubbing: Binding<Bool>

    @EnvironmentObject
    private var scrubbedSecondsBox: PublishedBox<Duration>

    @ObservedObject
    private var manager: MediaPlayerManager

    init(
        manager: MediaPlayerManager
    ) {
        self.manager = manager
    }

    var body: some View {
        switch manager.state {
        case .loadingItem:
            ProgressView()
        case let .error(error):
            Text(error.localizedDescription)
        default:
            NativeVideoPlayerView(
                manager: manager
            )
        }
    }
}

struct NativeVideoPlayerView: UIViewControllerRepresentable {

    let manager: MediaPlayerManager

    func makeUIViewController(context: Context) -> UINativeVideoPlayerViewController {
        UINativeVideoPlayerViewController(manager: manager)
    }

    func updateUIViewController(_ uiViewController: UINativeVideoPlayerViewController, context: Context) {}
}

class UINativeVideoPlayerViewController: AVPlayerViewController {

    private let logger = Logger.swiftfin()
    private let manager: MediaPlayerManager
    private var avPlayerManagerDelegate: AVPlayerManagerDelegate?

    init(
        manager: MediaPlayerManager,
    ) {
        self.manager = manager

        super.init(nibName: nil, bundle: nil)

        let newPlayer: AVPlayer = .init()

        newPlayer.allowsExternalPlayback = true
        newPlayer.appliesMediaSelectionCriteriaAutomatically = false
        allowsPictureInPicturePlayback = true

        #if !os(tvOS)
        updatesNowPlayingInfoCenter = false
        #endif

        player = newPlayer
        self.avPlayerManagerDelegate = AVPlayerManagerDelegate(manager: manager)
        self.avPlayerManagerDelegate?.set(player: newPlayer)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
