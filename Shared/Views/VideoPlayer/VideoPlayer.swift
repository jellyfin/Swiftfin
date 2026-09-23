//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import FactoryKit
import SwiftUI
import Transmission

struct VideoPlayer: View {

    @Environment(\.presentationCoordinator)
    private var presentationCoordinator

    @InjectedObject(\.mediaPlayerManager)
    private var manager: MediaPlayerManager

    @LazyState
    private var proxy: any VideoMediaPlayerLayoutConfigurable

    @Router
    private var router

    @State
    private var audioOffset: Duration = .zero
    @State
    private var isBeingDismissedByTransition = false

    #if os(iOS)
    @State
    private var scrubbingStartTime: CFTimeInterval? = nil
    #endif
    @State
    private var subtitleOffset: Duration = .zero

    @State
    private var viewState: ViewState = .init()

    init() {
        switch Defaults[.VideoPlayer.videoPlayerType] {
        case .mpv:
            self._proxy = .init(wrappedValue: MPVMediaPlayerProxy())
        case .native, .vlc:
            self._proxy = .init(wrappedValue: VLCMediaPlayerProxy())
        }
    }

    var body: some View {
        Container(
            viewState: viewState,
            manager: manager,
            videoSize: proxy.videoSize
        ) { videoLayout in
            proxy.videoPlayerBody(layout: videoLayout)
                .eraseToAnyView()
        } playbackControls: {
            PlaybackControls()
        }
        .onAppear {
            manager.proxy = proxy
            manager.start()
        }
        .prefersStatusBarHidden(!viewState.isPresentingControls)
        .onChange(of: audioOffset) {
            if let proxy = proxy as? MediaPlayerOffsetConfigurable {
                proxy.setAudioOffset(audioOffset)
            }
        }
        #if os(iOS)
        .onChange(of: viewState.isScrubbing) {
            if viewState.isScrubbing {
                scrubbingStartTime = CACurrentMediaTime()
                return
            }

            guard let scrubbingStartTime else { return }
            self.scrubbingStartTime = nil
            let scrubbingDelta = CACurrentMediaTime() - scrubbingStartTime
            let secondsDelta = abs(manager.seconds - viewState.scrubbedSeconds.value)

            guard secondsDelta >= .seconds(1), scrubbingDelta >= 0.1 else { return }

            let scrubbedSeconds = viewState.scrubbedSeconds.value
            manager.seconds = scrubbedSeconds
            proxy.setSeconds(scrubbedSeconds)
        }
        #endif
        .onChange(of: subtitleOffset) {
            if let proxy = proxy as? MediaPlayerOffsetConfigurable {
                proxy.setSubtitleOffset(subtitleOffset)
            }
        }
        .preference(
            key: PresentationControllerShouldDismissPreferenceKey.self,
            value: viewState.presentationControllerShouldDismiss
        )
        .onChange(of: presentationCoordinator.isPresented) {
            guard !presentationCoordinator.isPresented else { return }
            isBeingDismissedByTransition = true
            manager.stop()
        }
        .onReceive(manager.$playbackItem) { newItem in
            audioOffset = .zero
            subtitleOffset = .zero

            // TODO: move to container view
            viewState.scrubbedSeconds.value = newItem?.baseItem.startSeconds ?? .zero
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
                FactoryKit.Container.shared.mediaPlayerManager.reset()
                router.dismiss()
            }
        } message: {
            Text(L10n.unableToLoadThisItem)
        }
    }
}
