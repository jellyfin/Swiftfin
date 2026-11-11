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
import JellyfinAPI
import Observation

@MainActor
@Observable
final class JellyfinCastController {

    private(set) var devices: [SessionInfoDto] = []

    @ObservationIgnored
    private var discovery: AnyCancellable?
    @ObservationIgnored
    private var refreshTask: Task<Void, Never>?

    func startDiscovery() {
        let userSessionManager = Container.shared.userSessionManager()

        discovery = userSessionManager
            .$currentSession
            .map { session -> AnyPublisher<[SessionInfoDto], Never> in
                session?.serverSocketManager.sessions() ?? Combine.Empty<[SessionInfoDto], Never>().eraseToAnyPublisher()
            }
            .switchToLatest()
            .sink { [weak self] sessions in
                Task { @MainActor in
                    self?.didUpdateDeviceList(sessions)
                }
            }

        // The sessions socket is event-driven, so the current list is also fetched once.
        refreshTask = Task { [weak self] in
            guard let userSession = userSessionManager.currentSession else { return }

            let parameters = Paths.GetSessionsParameters(
                controllableByUserID: userSession.user.id,
                activeWithinSeconds: 900
            )

            guard let response = try? await userSession.send(Paths.getSessions(parameters: parameters)),
                  !Task.isCancelled else { return }

            defer { withExtendedLifetime(response) {} }

            self?.didUpdateDeviceList(response.value)
        }
    }

    func stopDiscovery() {
        discovery = nil
        refreshTask?.cancel()
        refreshTask = nil
    }

    private func didUpdateDeviceList(_ sessions: [SessionInfoDto]) {
        guard let userSession = Container.shared.userSessionManager().currentSession else {
            devices = []
            return
        }

        devices = sessions
            .filter { $0.isCastTarget(for: userSession) }
            .sorted()
    }

    func select(_ device: SessionInfoDto, for mediaSession: MediaSession) {
        guard mediaSession.canControlPlayback,
              mediaSession.item.mediaType == .video,
              (mediaSession.player as? JellyfinCastMediaPlayer)?.sessionID != device.id else { return }

        mediaSession.transfer(to: JellyfinCastMediaPlayer(session: device))
    }
}
