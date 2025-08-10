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
                manager: manager,
                scrubbedSeconds: $scrubbedSecondsBox.value
            )
        }
    }
}

struct NativeVideoPlayerView: UIViewControllerRepresentable {

    let manager: MediaPlayerManager
    let scrubbedSeconds: Binding<Duration>

    func makeUIViewController(context: Context) -> UINativeVideoPlayerViewController {
        UINativeVideoPlayerViewController(
            manager: manager,
            isScrubbing: context.environment.isScrubbing,
            scrubbedSeconds: scrubbedSeconds
        )
    }

    func updateUIViewController(_ uiViewController: UINativeVideoPlayerViewController, context: Context) {}
}
