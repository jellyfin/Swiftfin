//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension VideoPlayer {

    struct MainOverlay: View {

        @Environment(\.currentOverlayType)
        @Binding
        private var currentOverlayType
        @Environment(\.isPresentingOverlay)
        @Binding
        private var isPresentingOverlay
        @Environment(\.isScrubbing)
        @Binding
        private var isScrubbing: Bool

        @EnvironmentObject
        private var currentProgressHandler: VideoPlayerManager.CurrentProgressHandler
        @EnvironmentObject
        private var overlayTimer: TimerProxy

        var body: some View {
            VStack {

                Spacer()

                VideoPlayer.Overlay.BottomBarView()
                    .padding2()
                    .padding2()
                    .background {
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0),
                                .init(color: .black.opacity(0.8), location: 1),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
            }
            .environmentObject(overlayTimer)
        }
    }
}

// struct VideoPlayerOverlay_Preview: PreviewProvider {
//
//    static var previews: some View {
//        ZStack {
//
//            Color.red
//
//            VideoPlayer.MainOverlay()
//                .environmentObject(VideoPlayerManager())
//                .environmentObject(VideoPlayerViewModel(
//                    playbackURL: URL(string: "http://apple.com")!,
//                    item: .init(indexNumber: 1, name: "Interstellar", parentIndexNumber: 1, seriesName: "New Girl", type: .episode),
//                    mediaSource: .init(),
//                    playSessionID: "",
//                    videoStreams: [],
//                    audioStreams: [],
//                    subtitleStreams: [],
//                    selectedAudioStreamIndex: 1,
//                    selectedSubtitleStreamIndex: 1,
//                    chapters: [],
//                    streamType: .direct)
//                )
//                .environmentObject(VideoPlayerManager.CurrentProgressHandler())
//                .environmentObject(TimerProxy())
//        }
//        .ignoresSafeArea()
//    }
// }
