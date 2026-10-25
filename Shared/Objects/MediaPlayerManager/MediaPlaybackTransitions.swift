//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
import Foundation

/// Owns pending background and PiP transitions for one playback session.
@MainActor
final class MediaPlaybackTransitions {

    private weak var mediaSession: MediaSession?
    private var pictureInPicture: AnyCancellable?
    private var backgroundPause: AnyCancellable?

    init(mediaSession: MediaSession) {
        self.mediaSession = mediaSession
    }

    func reset() {
        pictureInPicture = nil
        backgroundPause = nil
    }

    func sceneDidEnterBackground() {
        cancelBackgroundPause()

        guard let mediaSession, !mediaSession.isRemotePlayback, mediaSession.item.mediaType != .audio,
              Defaults[.VideoPlayer.Transition.pauseOnBackground] else { return }

        let provider = mediaSession.player as? MediaPlayerPictureInPictureProviding
        guard provider?.isPiPActive != true else { return }
        guard let provider, provider.allowsAutomaticPiP || provider.isPiPTransitioning else {
            mediaSession.setPlaybackRequestStatus(status: .paused)
            return
        }

        // AVKit may announce automatic PiP after the scene enters the background.
        backgroundPause = Task { [weak mediaSession] in
            for _ in 0 ..< 5 {
                do {
                    try await Task.sleep(for: .milliseconds(300))
                } catch {
                    return
                }

                if provider.isPiPActive {
                    return
                }
            }

            guard !Task.isCancelled else { return }

            mediaSession?.setPlaybackRequestStatus(status: .paused)
        }
        .asAnyCancellable()
    }

    func cancelBackgroundPause() {
        backgroundPause = nil
    }

    func startPictureInPicture() {
        pictureInPicture = nil

        guard let mediaSession, let provider = mediaSession.player as? MediaPlayerPictureInPictureProviding else { return }

        pictureInPicture = Task { [weak mediaSession] in
            for _ in 0 ..< 5 {
                guard !Task.isCancelled, mediaSession?.state == .playback else { return }

                if provider.isPiPActive {
                    return
                }

                if provider.isPiPAvailable {
                    provider.startPiP()
                }

                do {
                    try await Task.sleep(for: .milliseconds(300))
                } catch {
                    return
                }
            }
        }
        .asAnyCancellable()
    }

    func stopPictureInPicture() {
        pictureInPicture = nil
        (mediaSession?.player as? MediaPlayerPictureInPictureProviding)?.stopPiP()
    }
}
