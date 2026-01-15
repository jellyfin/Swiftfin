//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import JellyfinAPI
import OrderedCollections

@MainActor
@Stateful
final class ServerUserAdminViewModel: ViewModel, Identifiable {

    @CasePathable
    enum Action {
        case cancel
        case refresh
        case getLibraries(isHidden: Bool? = false)
        case updatePolicy(UserPolicy)
        case updateConfiguration(UserConfiguration)
        case updateUsername(String)

        var transition: Transition {
            switch self {
            case .cancel:
                .to(.initial)
            case .refresh, .getLibraries:
                .to(.initial, then: .content)
                    .whenBackground(.refreshing)
            case .updatePolicy, .updateConfiguration, .updateUsername:
                .background(.updating)
            }
        }
    }

    enum BackgroundState {
        case updating
        case refreshing
    }

    enum Event {
        case updated
    }

    enum State {
        case initial
        case content
        case error
    }

    @Published
    private(set) var user: UserDto
    @Published
    var libraries: [BaseItemDto] = []

    init(user: UserDto? = nil) {

        self.user = .init()

        super.init()

        self.user = user ?? userSession.user.data

        Notifications[.didChangeUserProfile]
            .publisher
            .sink { [weak self] userID in
                guard let self, userID == self.user.id else { return }

                self.refresh()
            }
            .store(in: &cancellables)
    }

    @Function(\Action.Cases.refresh)
    private func _refresh() async throws {
        user = try await user.getFullUser(userSession: userSession)
    }

    @Function(\Action.Cases.getLibraries)
    private func _getLibraries(_ isHidden: Bool?) async throws {
        let request = Paths.getMediaFolders(isHidden: isHidden)
        let response = try await userSession.client.send(request)

        libraries = response.value.items ?? []
    }

    @Function(\Action.Cases.updatePolicy)
    private func _updatePolicy(_ policy: UserPolicy) async throws {
        guard let userID = user.id else {
            throw ErrorMessage("User ID is missing")
        }

        let request = Paths.updateUserPolicy(userID: userID, policy)
        try await userSession.client.send(request)

        user.policy = policy
        events.send(.updated)
    }

    @Function(\Action.Cases.updateConfiguration)
    private func _updateConfiguration(_ configuration: UserConfiguration) async throws {
        guard let userID = user.id else {
            throw ErrorMessage("User ID is missing")
        }

        let request = Paths.updateUserConfiguration(userID: userID, configuration)
        try await userSession.client.send(request)

        user.configuration = configuration
        events.send(.updated)
    }

    @Function(\Action.Cases.updateUsername)
    private func _updateUsername(_ username: String) async throws {
        guard let userID = user.id else {
            throw ErrorMessage("User ID is missing")
        }

        var updatedUser = user
        updatedUser.name = username

        let request = Paths.updateUser(userID: userID, updatedUser)
        try await userSession.client.send(request)

        user.name = username

        Notifications[.didChangeUserProfile].post(userID)
        events.send(.updated)
    }
}
