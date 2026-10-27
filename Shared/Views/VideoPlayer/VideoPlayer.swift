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

    #if os(iOS)
    private var remotePlaybackBody: some View {
        VStack(spacing: 16) {
            Image(systemName: "tv")
                .font(.system(size: 56))

            // swiftlint:disable:next nested_l10n
            Text(L10n.castingTo(mediaSession.player?.displayTitle ?? L10n.unknown))
                .font(.title2)

            if mediaSession.state == .playback, !mediaSession.playbackState.isReady {
                Text(L10n.castConnectionSuspended)
                    .font(.callout)
            }
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black)
    }
    #endif

    var body: some View {
        #if os(iOS)
        if #available(iOS 27.1, *) {
            // A fullscreen player keeps horizontal bars instead of the Duo's vertical bar.
            playerContent
                .toolbarVerticalBehavior(.disabled)
        } else {
            playerContent
        }
        #else
        playerContent
        #endif
    }

    private var playerContent: some View {
        Container(
            viewState: viewState,
            mediaSession: mediaSession,
            videoSize: { (mediaSession.player as? any VideoMediaPlayer)?.videoState.videoSize ?? .zero }
        ) { videoLayout in
            if let player = mediaSession.player as? any VideoMediaPlayer {
                return player.videoPlayerBody(layout: videoLayout).eraseToAnyView()
            }

            #if os(iOS)
            if mediaSession.isRemotePlayback {
                return remotePlaybackBody.eraseToAnyView()
            }
            #endif

            return Color.black.eraseToAnyView()
        } playbackControls: {
            PlaybackControls()
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
        .supportedOrientations(UIDevice.rotatesFreely ? .all : .allButUpsideDown)
        .ignoresSafeArea()
        .persistentSystemOverlays(.hidden)
        .toolbar(.hidden, for: .navigationBar)
        .onSizeChanged { _, safeArea in
            self.safeAreaInsets = safeArea.max(EdgeInsets.edgePadding)
        }
    }
}
