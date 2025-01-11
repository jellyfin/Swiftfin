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

// extension VideoPlayer {
//
//    struct Overlay: View {
//
//        @Environment(\.isPresentingOverlay)
//        @Binding
//        private var isPresentingOverlay
//
//        @EnvironmentObject
//        private var proxy: VLCVideoPlayer.Proxy
//        @EnvironmentObject
//        private var router: VideoPlayerCoordinator.Router
//        @EnvironmentObject
//        private var videoPlayerManager: VideoPlayerManager
//
//        @State
//        private var confirmCloseWorkItem: DispatchWorkItem?
//        @State
//        private var currentOverlayType: OverlayType = .main
//
//        @StateObject
//        private var overlayTimer: DelayIntervalTimer = .init()
//
//        @ViewBuilder
//        private var currentOverlay: some View {
//            switch currentOverlayType {
////            case .chapters:
////                ChapterOverlay()
//            case .confirmClose:
//                ConfirmCloseOverlay()
//            case .main:
//                MainOverlay()
////            case .smallMenu:
////                SmallMenuOverlay()
//            }
//        }
//
//        var body: some View {
//            currentOverlay
//                .visible(isPresentingOverlay)
//                .animation(.linear(duration: 0.1), value: currentOverlayType)
////                .environment(\.currentOverlayType, $currentOverlayType)
//                .environmentObject(overlayTimer)
////                .onChange(of: currentOverlayType) { _, newValue in
////                    if [.smallMenu, .chapters].contains(newValue) {
////                        overlayTimer.pause()
////                    } else if isPresentingOverlay {
////                        overlayTimer.delay()
////                    }
////                }
////                .onChange(of: overlayTimer.isActive) { _, isActive in
////                    guard !isActive else { return }
////
////                    withAnimation(.linear(duration: 0.3)) {
////                        isPresentingOverlay = false
////                    }
////                }
////                .onSelectPressed {
////                    currentOverlayType = .main
////                    isPresentingOverlay = true
////                    overlayTimer.delay()
////                }
////                .onMenuPressed {
////
////                    overlayTimer.delay()
////                    confirmCloseWorkItem?.cancel()
////
////                    if isPresentingOverlay && currentOverlayType == .confirmClose {
////                        proxy.stop()
////                        router.dismissCoordinator()
////                    } else if isPresentingOverlay && currentOverlayType == .smallMenu {
////                        currentOverlayType = .main
////                    } else {
////                        withAnimation {
////                            currentOverlayType = .confirmClose
////                            isPresentingOverlay = true
////                        }
////
////                        let task = DispatchWorkItem {
////                            withAnimation {
////                                isPresentingOverlay = false
////                                overlayTimer.stop()
////                            }
////                        }
////
////                        confirmCloseWorkItem = task
////
////                        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: task)
////                    }
////                }
//                .onChange(of: isPresentingOverlay) {
//                    if !isPresentingOverlay {
//                        currentOverlayType = .main
//                    }
//                }
//                .onChange(of: currentOverlayType) { _, newValue in
//                    if [.smallMenu, .chapters].contains(newValue) {
//                        overlayTimer.pause()
//                    } else if isPresentingOverlay {
//                        overlayTimer.start(5)
//                    }
//                }
//                .onChange(of: overlayTimer.isActive) { _, isActive in
//                    guard !isActive else { return }
//
//                    withAnimation(.linear(duration: 0.3)) {
//                        isPresentingOverlay = false
//                    }
//                }
//                .pressCommands {
//                    PressCommandAction(title: L10n.back, press: .menu, action: menuPress)
//                    PressCommandAction(title: L10n.playAndPause, press: .playPause) {
//                        if videoPlayerManager.state == .playing {
//                            videoPlayerManager.proxy.pause()
//                            withAnimation(.linear(duration: 0.3)) {
//                                isPresentingOverlay = true
//                            }
//                        } else if videoPlayerManager.state == .paused {
//                            videoPlayerManager.proxy.play()
//                            withAnimation(.linear(duration: 0.3)) {
//                                isPresentingOverlay = false
//                            }
//                        }
//                    }
//                    PressCommandAction(title: L10n.pressDownForMenu, press: .upArrow, action: arrowPress)
//                    PressCommandAction(title: L10n.pressDownForMenu, press: .downArrow, action: arrowPress)
//                    PressCommandAction(title: L10n.pressDownForMenu, press: .leftArrow, action: arrowPress)
//                    PressCommandAction(title: L10n.pressDownForMenu, press: .rightArrow, action: arrowPress)
//                    PressCommandAction(title: L10n.pressDownForMenu, press: .select, action: arrowPress)
//                }
//        }
//
//        func arrowPress() {
//            if isPresentingOverlay { return }
//            currentOverlayType = .main
//            overlayTimer.start(5)
//            withAnimation {
//                isPresentingOverlay = true
//            }
//        }
//
//        func menuPress() {
//            overlayTimer.start(5)
//            confirmCloseWorkItem?.cancel()
//
//            if isPresentingOverlay && currentOverlayType == .confirmClose {
//                proxy.stop()
//                router.dismissCoordinator()
//            } else if isPresentingOverlay && currentOverlayType == .smallMenu {
//                currentOverlayType = .main
//            } else {
//                withAnimation {
//                    currentOverlayType = .confirmClose
//                    isPresentingOverlay = true
//                }
//
//                let task = DispatchWorkItem {
//                    withAnimation {
//                        isPresentingOverlay = false
//                        overlayTimer.stop()
//                    }
//                }
//
//                confirmCloseWorkItem = task
//
//                DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: task)
//            }
//        }
//    }
// }

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
