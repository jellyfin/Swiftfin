//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
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

    @Injected(\.networkMonitor)
    private var networkMonitor

    private let logger = Logger.swiftfin()
    private var cancellables = Set<AnyCancellable>()

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
                        // Check network status before server check
                        if networkMonitor.isConnected {
                            root(.serverCheck)
                        } else {
                            root(.offline)
                        }
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

        // Monitor network state changes
        networkMonitor.$isConnected
            .dropFirst() // Skip initial value
            .sink { [weak self] isConnected in
                Task { @MainActor [weak self] in
                    guard let self = self else { return }

                    // Only handle network changes if user is signed in
                    guard Container.shared.currentUserSession() != nil, !Defaults[.signOutOnClose] else { return }

                    #if os(iOS)
                    if isConnected && self.root.id == RootItem.offline.id {
                        // Network restored, go back to server check
                        self.root(.serverCheck)
                    } else if !isConnected && (self.root.id == RootItem.serverCheck.id || self.root.id == RootItem.mainTab.id) {
                        // Network lost, go to offline mode
                        self.root(.offline)
                    }
                    #endif
                }
            }
            .store(in: &cancellables)

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
        // Check network status when signing in
        if networkMonitor.isConnected {
            root(.serverCheck)
        } else {
            root(.offline)
        }
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
