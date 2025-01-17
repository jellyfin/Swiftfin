//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import PreferencesView
import SwiftUI
import VLCUI

extension VideoPlayer {

    struct Overlay: View {

        @Environment(\.isScrubbing)
        @Binding
        private var isScrubbing: Bool

        // since this view ignores safe area, it must
        // get safe area insets from parent views
        @Environment(\.safeAreaInsets)
        private var safeAreaInsets

        @EnvironmentObject
        private var manager: MediaPlayerManager

        @State
        private var contentSize: CGSize = .zero
        @State
        private var effectiveSafeArea: EdgeInsets = .zero
        @State
        private var isPresentingOverlay: Bool = true
        @State
        private var progressViewFrame: CGRect = .zero
        @State
        private var selectedSupplement: AnyMediaPlayerSupplement?

        @StateObject
        private var overlayTimer: PokeIntervalTimer = .init()

        private var isPresentingSupplement: Bool {
            selectedSupplement != nil
        }

        @ViewBuilder
        private var bottomContent: some View {
            if !isPresentingSupplement {

                NavigationBar()
                    .focusSection()

//                PlaybackProgress()
//                    .isVisible(isScrubbing || isPresentingOverlay)
//                    .transition(.move(edge: .top).combined(with: .opacity))
//                    .trackingFrame($progressViewFrame)
            }

//            HStack(spacing: 10) {
//                ForEach(manager.supplements.map(\.asAny)) { supplement in
//                    DrawerSectionButton(
//                        supplement: supplement
//                    )
//                }
//            }
//            .isVisible(!isScrubbing && isPresentingOverlay)
        }

        var body: some View {
            ZStack {

//                OpacityLinearGradient {
//                    (0, 0)
//                    (1, 0.5)
//                }
//                .foregroundStyle(.black)
//                .isVisible(isScrubbing || isPresentingOverlay)
//                .frame(height: progressViewFrame.height)
//                .animation(.linear(duration: 0.25), value: isPresentingOverlay)

                VStack {
                    Spacer()

                    bottomContent
                }
            }
            .animation(.linear(duration: 0.1), value: isScrubbing)
            .animation(.bouncy(duration: 0.4), value: isPresentingSupplement)
            .animation(.bouncy(duration: 0.25), value: isPresentingOverlay)
            .environment(\.isPresentingOverlay, $isPresentingOverlay)
            .environment(\.selectedMediaPlayerSupplement, $selectedSupplement)
//            .environmentObject(jumpProgressObserver)
            .environmentObject(overlayTimer)
            .onChange(of: isPresentingOverlay) {
                guard isPresentingOverlay, !isScrubbing else { return }
                overlayTimer.poke()
            }
            .onChange(of: isScrubbing) {
                if isScrubbing {
                    overlayTimer.stop()
                } else {
                    overlayTimer.poke()
                }
            }
            .onReceive(overlayTimer.hasFired) {
                guard !isScrubbing else { return }

                withAnimation(.linear(duration: 0.25)) {
                    isPresentingOverlay = false
                }
            }
            .onChange(of: selectedSupplement) {
                if selectedSupplement == nil {
                    overlayTimer.poke()
                } else {
                    overlayTimer.stop()
                }
            }
        }
    }
}

import VLCUI

struct VideoPlayer_Overlay_Previews: PreviewProvider {

    static var previews: some View {
        VideoPlayer.Overlay()
            .environmentObject(
                MediaPlayerManager(
                    playbackItem: .init(
                        baseItem: .init(
                            //                            channelType: .tv,
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
            .environment(\.isScrubbing, .mock(false))
            .environment(\.isAspectFilled, .mock(false))
            .environment(\.isPresentingOverlay, .constant(true))
//            .environment(\.playbackSpeed, .constant(1.0))
            .environment(\.selectedMediaPlayerSupplement, .mock(nil))
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
