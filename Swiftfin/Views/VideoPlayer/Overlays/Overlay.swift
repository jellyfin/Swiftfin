//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension VideoPlayer {

    struct Overlay: View {

        @Environment(\.isPresentingOverlay)
        @Binding
        private var isPresentingOverlay

        var body: some View {
            ZStack {

                MainOverlay()

//                ChapterOverlay()
//                    .visible(currentOverlayType == .chapters)
            }
//            .animation(.linear(duration: 0.1), value: currentOverlayType)
//            .environment(\.currentOverlayType, $currentOverlayType)
//            .onChange(of: isPresentingOverlay) { newValue in
//                guard newValue else { return }
//                currentOverlayType = .main
//            }
        }
    }
}

import VLCUI

struct VideoPlayer_Overlay_Previews: PreviewProvider {

    static var previews: some View {
        VideoPlayer.Overlay()
//            .environmentObject(VideoPlayerManager(playbackItem: .init(
//                baseItem: .init(name: "Top Gun Maverick", runTimeTicks: 10_000_000_000),
//                mediaSource: .init(),
//                playSessionID: "",
//                url: URL(string: "/")!
//            )))
                .environmentObject(VideoPlayerManager(playbackItem: .init(
                    baseItem: .init(indexNumber: 1, name: "The Bear", parentIndexNumber: 1, runTimeTicks: 10_000_000_000, type: .episode),
                    mediaSource: .init(),
                    playSessionID: "",
                    url: URL(string: "/")!
                )))
                .environmentObject(ProgressBox(progress: 0, seconds: 100))
                .environmentObject(VLCVideoPlayer.Proxy())
                .environment(\.isScrubbing, .mock(false))
                .environment(\.isAspectFilled, .mock(false))
                .environment(\.isPresentingOverlay, .constant(true))
                .environment(\.playbackSpeed, .constant(1.0))
                .previewInterfaceOrientation(.landscapeLeft)
                .preferredColorScheme(.dark)
    }
}

extension Binding {
    static func mock(_ value: Value) -> Self {
        var value = value
        return Binding(
            get: { value },
            set: { value = $0 }
        )
    }
}
