//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
import Factory
import Logging
import SwiftUI

@MainActor
final class RootCoordinator: ObservableObject {

    @Published
    var root: RootItem = .appLoading

    private var cancellables: Set<AnyCancellable> = []
    private let logger = Logger.swiftfin()

    init() {
        Task {
            do {
                try await SwiftfinStore.setupDataStack()

                // DEV CONVENIENCE: on a clean install (no session), connect + sign in with the
                // owner's hardcoded home-server credentials so updates don't force onboarding.
                // No-ops once a session exists. Remove via BrunoDevAutoLogin.isEnabled = false.
                await BrunoDevAutoLogin.runIfNeeded()

                if Container.shared.currentUserSession() != nil, !Defaults[.signOutOnClose] {
                    #if os(tvOS)
                    await MainActor.run {
                        root(.mainTab)
                    }
                    #else
                    await MainActor.run {
                        root(.serverCheck)
                    }
                    #endif
                } else {
                    await MainActor.run {
                        root(.selectUser)
                    }
                }

            } catch {
                await MainActor.run {
                    Notifications[.didFailMigration].post()
                }
            }
        }

        Notifications[.didChangeUserSession]
            .publisher
            .sink(receiveValue: didChangeUserSession)
            .store(in: &cancellables)

        Notifications[.didChangeServerConnection]
            .publisher
            .sink(receiveValue: didChangeServerConnection)
            .store(in: &cancellables)
    }

    func root(_ newRoot: RootItem) {
        root = newRoot
    }

    private func didChangeUserSession() {
        guard Container.shared.currentUserSession() != nil else {
            logger.info("Signed out")
            root(.selectUser)
            return
        }

        logger.info("Signed in")

        #if os(tvOS)
        root(.mainTab)
        #else
        root(.serverCheck)
        #endif
    }

    private func didChangeServerConnection(_ connection: ServerConnection) {

        guard Container.shared.currentUserSession() != nil else { return }

        Container.shared.userSessionManager().refreshCurrentSession()
        Notifications[.didChangeUserSession].post()
    }
}
