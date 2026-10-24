//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct VideoPlayer: View {

    @Router
    private var router

    @State
    private var safeAreaInsets: EdgeInsets = .init()
    @State
    private var viewState: ViewState = .init()

    let mediaSession: MediaSession

    var body: some View {
        ZStack {
            if let player = mediaSession.player as? any VideoMediaPlayer {
                Container(
                    viewState: viewState,
                    mediaSession: mediaSession,
                    videoSize: { player.videoState.videoSize }
                ) { videoLayout in
                    player.videoPlayerBody(layout: videoLayout)
                        .eraseToAnyView()
                } playbackControls: {
                    PlaybackControls()
                }
                .id(ObjectIdentifier(player))
            } else {
                Color.black
            }
        }
        .onAppear {
            if mediaSession.player == nil, mediaSession.state != .stopped {
                mediaSession.attach(player: Defaults[.VideoPlayer.mediaPlayerType].makePlayer())
            }
        }
        .prefersStatusBarHidden(!viewState.isPresentingControls)
        .onChange(of: mediaSession.commandError, initial: true) { _, message in
            guard let message else { return }

            viewState.toastProxy.present(message, systemName: "exclamationmark.triangle")
        }
        .preference(
            key: PresentationControllerShouldDismissPreferenceKey.self,
            value: viewState.presentationControllerShouldDismiss
        )
        .onChange(of: mediaSession.state, initial: true) { _, newState in
            if newState == .stopped, !viewState.isBeingDismissed {
                router.dismiss()
            }
        }
        .alert(
            L10n.error,
            isPresented: .constant(mediaSession.state == .error)
        ) {
            Button(L10n.retry) { mediaSession.retry() }

            Button(L10n.close, role: .cancel) {
                mediaSession.stop()
                router.dismiss()
            }
        } message: {
            Text(L10n.unableToLoadThisItem)
        }
        .environment(\.safeAreaInsets, safeAreaInsets)
        .colorScheme(.dark)
        .supportedOrientations(.allButUpsideDown)
        .ignoresSafeArea()
        .persistentSystemOverlays(.hidden)
        .toolbar(.hidden, for: .navigationBar)
        .onSizeChanged { _, safeArea in
            self.safeAreaInsets = safeArea.max(EdgeInsets.edgePadding)
        }
    }
}
