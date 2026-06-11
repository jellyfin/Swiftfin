//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
import SwiftUI
import Transmission

struct VideoPlayer: View {

    @Environment(\.presentationCoordinator)
    private var presentationCoordinator

    @InjectedObject(\.mediaPlayerManager)
    private var manager: MediaPlayerManager

    @LazyState
    private var proxy: any VideoMediaPlayerProxy

    @Router
    private var router

    // TODO: move audio/subtitle offset to container state?
    @State
    private var audioOffset: Duration = .zero
    @State
    private var isBeingDismissedByTransition = false
    @State
    private var safeAreaInsets: EdgeInsets = .init()

    // TODO: move behavior to `PlaybackProgress`
    @State
    private var scrubbingStartDate: Date? = nil
    @State
    private var subtitleOffset: Duration = .zero

    @StateObject
    private var containerState: VideoPlayerContainerState = .init()

    init() {
        switch Defaults[.VideoPlayer.videoPlayerType] {
        case .avPlayer:
            self._proxy = .init(wrappedValue: AVMediaPlayerProxy())
        case .vlc:
            self._proxy = .init(wrappedValue: VLCMediaPlayerProxy())
        }
    }

    @ViewBuilder
    private var containerView: some View {
        VideoPlayerContainerView(
            containerState: containerState,
            manager: manager
        ) {
            proxy.videoPlayerBody
                .eraseToAnyView()
        } playbackControls: {
            PlaybackControls()
        }
        .onAppear {
            manager.proxy = proxy
            manager.start()
        }
    }

    var body: some View {
        containerView
            .environment(\.safeAreaInsets, safeAreaInsets)
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
                if newValue { scrubbingStartDate = .now }

                guard let scrubbingStartDate else { return }
                let scrubbingDelta = Date.now.timeIntervalSince(scrubbingStartDate)
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
            .colorScheme(.dark) // use over `preferredColorScheme(.dark)` to not have destination change
            .supportedOrientations(.allButUpsideDown)
            .ignoresSafeArea()
            .persistentSystemOverlays(.hidden)
            .toolbar(.hidden, for: .navigationBar)
            .onSizeChanged { _, safeArea in
                self.safeAreaInsets = safeArea.max(EdgeInsets.edgePadding)
            }
    }
}
