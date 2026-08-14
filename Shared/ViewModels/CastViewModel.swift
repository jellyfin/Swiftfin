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
import OrderedCollections

@MainActor
@Stateful
final class CastViewModel: ViewModel {

    @CasePathable
    enum Action {
        case refresh

        var transition: Transition {
            .to(.initial, then: .content)
                .whenBackground(.refreshing)
        }
    }

    enum BackgroundState {
        case refreshing
    }

    enum State {
        case content
        case error
        case initial
    }

    @Published
    private(set) var selectedTarget: SessionViewModel?
    @Published
    private(set) var targets: OrderedDictionary<String, SessionViewModel> = [:]

    var isPaused: Bool = false {
        didSet {
            pausedSince = isPaused ? .now : nil
        }
    }

    private var pausedSince: Date?

    override init() {
        super.init()

        Container.shared.userSessionManager()
            .$currentSession
            .map { session -> AnyPublisher<[SessionInfoDto], Never> in
                session?.serverSocketManager.sessions() ?? Combine.Empty<[SessionInfoDto], Never>().eraseToAnyPublisher()
            }
            .switchToLatest()
            .sink { [weak self] sessions in
                Task { @MainActor in
                    self?.updateTargets(sessions)
                }
            }
            .store(in: &cancellables)
    }

    @Function(\Action.Cases.refresh)
    private func _refresh() async throws {
        let parameters = try Paths.GetSessionsParameters(
            controllableByUserID: authenticatedUser.id,
            activeWithinSeconds: 900
        )
        let request = Paths.getSessions(parameters: parameters)
        let response = try await send(request)

        updateTargets(response.value)
    }

    func select(_ target: SessionViewModel?) {
        selectedTarget = target
        Container.shared.userSessionManager().castDeviceID = target?.session.deviceID
    }

    func isPlaying(item: BaseItemDto) -> Bool {
        targets.values.contains { target in
            CastMediaPlayerProxy.isPlaying(item: item, in: target.session)
        }
    }

    private func updateTargets(_ incomingSessions: [SessionInfoDto]) {
        if let pausedSince, Date.now.timeIntervalSince(pausedSince) < 15 {
            return
        }

        guard let userSession else { return }

        let deviceID = userSession.client.configuration.deviceID
        let userID = userSession.user.id

        var updatedTargets: OrderedDictionary<String, SessionViewModel> = [:]

        let controllableSessions = incomingSessions
            .filter { session in
                session.isSupportsRemoteControl == true
                    && session.deviceID != deviceID
                    && session.userID == userID
                    && session.playableMediaTypes?.contains(.video) == true
            }
            .sorted()

        for session in controllableSessions {
            guard let id = session.id else { continue }

            if let existing = targets[id] {
                existing.session = session
                updatedTargets[id] = existing
            } else {
                updatedTargets[id] = SessionViewModel(session: session)
            }
        }

        targets = updatedTargets

        if let selectedTarget, let id = selectedTarget.id, updatedTargets[id] == nil {
            self.selectedTarget = nil
        }

        if selectedTarget == nil, let lastDeviceID = Container.shared.userSessionManager().castDeviceID {
            selectedTarget = updatedTargets.values.first { $0.session.deviceID == lastDeviceID }
        }
    }
}
