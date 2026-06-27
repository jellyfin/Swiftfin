//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Factory
import SwiftUI
import Transmission

struct VideoPlayer: View {

    @Environment(\.presentationCoordinator)
    private var presentationCoordinator

    @InjectedObject(\.mediaPlayerManager)
    private var manager: MediaPlayerManager

    #if os(tvOS)
    // Drives the full-screen SyncPlay border (shown while in a group, riding in/out with the controls).
    @InjectedObject(\.syncPlayManager)
    private var syncPlayManager
    #endif

    @LazyState
    private var proxy: any VideoMediaPlayerProxy

    @Router
    private var router

    // TODO: move audio/subtitle offset to container state?
    @State
    private var audioOffset: Duration = .zero
    @State
    private var isBeingDismissedByTransition = false

    // TODO: move behavior to `PlaybackProgress`?
    @State
    private var scrubbingStartTime: CFTimeInterval? = nil
    @State
    private var subtitleOffset: Duration = .zero

    @StateObject
    private var containerState: VideoPlayerContainerState = .init()

    init() {
        self._proxy = .init(wrappedValue: VLCMediaPlayerProxy())
    }

    var body: some View {
        VideoPlayerContainerView(
            containerState: containerState,
            manager: manager
        ) {
            proxy.videoPlayerBody
                .eraseToAnyView()
        } playbackControls: {
            PlaybackControls()
        }
        // The SyncPlay group border framing the ENTIRE player. Placed here (not in PlaybackControls) because
        // on tvOS the controls layer is pinned ~120pt above the screen bottom to clear the Info/Chapters bar,
        // which clipped the border there. This overlay sits on the full-screen container, so it reaches all
        // four edges. Tied to the overlay so it rides in/out with the playback controls.
        .overlay {
            #if os(tvOS)
            if syncPlayManager.state == .inGroup, containerState.isPresentingOverlay {
                SyncPlayActiveBorder(lineWidth: 5, cornerRadius: 25)
                    .transition(.opacity)
                    .allowsHitTesting(false)
            }
            #endif
        }
        // Watch Together event banners (user/group join & leave), lower-left. Mounted here too because the
        // full-screen player covers the app-level banner overlay. Always visible (not gated on the controls
        // overlay) so notifications show even while the controls are hidden.
        .overlay {
            #if os(tvOS)
            SyncPlayNotificationBanner()
            #endif
        }
        .animation(.easeInOut(duration: 0.25), value: containerState.isPresentingOverlay)
        .onAppear {
            manager.proxy = proxy
            manager.start()
        }
        .prefersStatusBarHidden(!containerState.isPresentingOverlay)
        .backport
        .onChange(of: audioOffset) { _, newValue in
            if let proxy = proxy as? MediaPlayerOffsetConfigurable {
                proxy.setAudioOffset(newValue)
            }
        }
        .backport
        .onChange(of: containerState.isAspectFilled) { _, newValue in
            UIView.animate(withDuration: 0.2) {
                proxy.setAspectFill(newValue)
            }
        }
        .backport
        .onChange(of: containerState.isScrubbing) { _, newValue in
            if newValue {
                scrubbingStartTime = CACurrentMediaTime()
            }

            guard let scrubbingStartTime else { return }
            let scrubbingDelta = CACurrentMediaTime() - scrubbingStartTime
            let secondsDelta = abs(manager.seconds - containerState.scrubbedSeconds.value)

            guard secondsDelta >= .seconds(1), scrubbingDelta >= 0.1 else { return }

            let scrubbedSeconds = containerState.scrubbedSeconds.value
            manager.seconds = scrubbedSeconds
            proxy.setSeconds(scrubbedSeconds)
        }
        .backport
        .onChange(of: subtitleOffset) { _, newValue in
            if let proxy = proxy as? MediaPlayerOffsetConfigurable {
                proxy.setSubtitleOffset(newValue)
            }
        }
        .preference(
            key: PresentationControllerShouldDismissPreferenceKey.self,
            value: containerState.presentationControllerShouldDismiss
        )
        .backport
        .onChange(of: presentationCoordinator.isPresented) { _, isPresented in
            guard !isPresented else { return }
            isBeingDismissedByTransition = true
            manager.stop()
        }
        .onReceive(manager.$playbackItem) { newItem in
            containerState.isAspectFilled = false
            audioOffset = .zero
            subtitleOffset = .zero

            // TODO: move to container view
            containerState.scrubbedSeconds.value = newItem?.baseItem.startSeconds ?? .zero
        }
        .onReceive(manager.$state) { newState in
            if newState == .stopped, !isBeingDismissedByTransition {
                router.dismiss()
            }
        }

        .alert(
            L10n.error,
            isPresented: .constant(manager.error != nil)
        ) {
            Button(L10n.close, role: .cancel) {
                Container.shared.mediaPlayerManager.reset()
                router.dismiss()
            }
        } message: {
            Text(L10n.unableToLoadThisItem)
        }
    }
}
