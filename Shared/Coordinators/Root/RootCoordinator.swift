//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
import Logging
import SwiftUI

@MainActor
final class RootCoordinator: ObservableObject {

    @Published
    var root: RootItem = .appLoading

    private let logger = Logger.swiftfin()

    init() {
        Task {
            do {
                try await SwiftfinStore.setupDataStack()

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

        // Notification setup for state
        Notifications[.didSignIn].subscribe(self, selector: #selector(didSignIn))
        Notifications[.didSignOut].subscribe(self, selector: #selector(didSignOut))
        Notifications[.didChangeCurrentServerURL].subscribe(self, selector: #selector(didChangeCurrentServerURL(_:)))
    }

    func root(_ newRoot: RootItem) {
        root = newRoot
    }

    @objc
    private func didSignIn() {
        logger.info("Signed in")

        #if os(tvOS)
        root(.mainTab)
        #else
        root(.serverCheck)
        #endif
    }

    @objc
    private func didSignOut() {
        logger.info("Signed out")

        root(.selectUser)
    }

    @objc
    func didChangeCurrentServerURL(_ notification: Notification) {

        guard Container.shared.currentUserSession() != nil else { return }

        Container.shared.currentUserSession.reset()
        Notifications[.didSignIn].post()
    }
}
