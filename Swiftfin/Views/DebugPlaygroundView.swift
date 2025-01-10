//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import PreferencesView
import SwiftUI
import VLCUI

struct DebugPlaygroundView: View {
    var body: some View {
        PreferencesView {
            TestPlaybackProgressView()
                .supportedOrientations(UIDevice.isPhone ? .landscape : .allButUpsideDown)
        }
    }
}

#if DEBUG
struct TestPlaybackProgressView: View {

    @ObserveInjection
    private var inject

    @State
    private var isScrubbing: Bool = false
    @State
    private var scrubbedSeconds: TimeInterval = 0

    var body: some View {
        VideoPlayer.Overlay()
            .environmentObject(
                MediaPlayerManager(
                    playbackItem: .init(
                        baseItem: .init(
                            indexNumber: 1,
                            name: "The Bear",
                            parentIndexNumber: 1,
                            runTimeTicks: 10_000_000_000,
                            type: .episode
                        ),
                        mediaSource: .init(),
                        playSessionID: "",
                        url: URL(string: "/")!
                    )
                )
            )
            .environmentObject(VLCVideoPlayer.Proxy())
            .environment(\.isScrubbing, $isScrubbing)
            .environment(\.isAspectFilled, .mock(false))
            .environment(\.isPresentingOverlay, .constant(true))
//            .environment(\.playbackSpeed, .constant(1.0))
            .environment(\.selectedMediaPlayerSupplement, .mock(nil))
            .environment(\.scrubbedSeconds, $scrubbedSeconds)
            .enableInjection()
    }
}
#endif
