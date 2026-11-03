//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import FactoryKit
import Foundation
import Observation

extension Container {

    var mediaPlayerManager: Factory<MediaPlayerManager> {
        self { MainActor.assumeIsolated { MediaPlayerManager() } }.singleton
    }
}

/// The app's permanent owner of playback sessions and system playback integration.
@MainActor
@Observable
final class MediaPlayerManager {

    private(set) var currentSession: MediaSession?

    @ObservationIgnored
    private let nowPlayableObserver: any MediaSessionObserver
    @ObservationIgnored
    private let reportQueue = MediaPlaybackReportQueue()
    @ObservationIgnored
    private let resolveItem: MediaSession.ItemResolver
    @ObservationIgnored
    private var sessionObservation: AnyCancellable?
    @ObservationIgnored
    private var nowPlayingObservation: AnyCancellable?
    @ObservationIgnored
    private var lifecycleObservations: Set<AnyCancellable> = []

    var hasActivePlayback: Bool {
        currentSession?.hasActivePlayback == true
    }

    init(
        nowPlayableObserver: any MediaSessionObserver? = nil,
        resolveItem: @escaping MediaSession.ItemResolver = { try await MediaPlayerItemResolver.resolve($0, for: $1, userSession: $2) }
    ) {
        self.nowPlayableObserver = nowPlayableObserver ?? NowPlayableObserver()
        self.resolveItem = resolveItem

        Notifications[.applicationWillTerminate]
            .publisher
            .sink { [weak self] _ in self?.stop() }
            .store(in: &lifecycleObservations)

        Notifications[.applicationDidEnterBackground]
            .publisher
            .sink { [weak self] _ in self?.currentSession?.sceneDidEnterBackground() }
            .store(in: &lifecycleObservations)

        Notifications[.applicationWillEnterForeground]
            .publisher
            .sink { [weak self] _ in self?.currentSession?.cancelBackgroundPause() }
            .store(in: &lifecycleObservations)
    }

    isolated deinit {
        currentSession?.stop()
    }

    @discardableResult
    func play(
        intent: PlaybackIntent,
        userSession: UserSession
    ) -> MediaSession {
        stop()

        var intent = intent
        if intent.queue == nil, intent.item.type == .episode {
            intent.queue = EpisodeMediaPlayerQueue()
        }

        let session = MediaSession(
            intent: intent,
            userSession: userSession,
            reportQueue: reportQueue,
            resolveItem: resolveItem
        )

        currentSession = session

        sessionObservation = session.core.statePublisher.sink { [weak self, weak session] state in
            guard let self, let session, currentSession === session else { return }

            switch state {
            case .preparing, .playback:
                if nowPlayingObservation == nil {
                    nowPlayingObservation = nowPlayableObserver.observe(session)
                }

            case .initial, .loadingItem, .error:
                nowPlayingObservation = nil

            case .stopped:
                nowPlayingObservation = nil
                sessionObservation = nil
                currentSession = nil
            }
        }

        return session
    }

    func stop() {
        currentSession?.stop()
    }
}
