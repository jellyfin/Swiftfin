//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
import SwiftUI

@MainActor
final class RootCoordinator: ObservableObject {

    @Published
    var root: RootItem = .appLoading

    init() {
        Task {
            do {
                try await SwiftfinStore.setupDataStack()

                if Container.shared.currentUserSession() != nil, !Defaults[.signOutOnClose] {
                    await MainActor.run {
                        root(.serverCheck)
                    }
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
    }

    func root(_ newRoot: RootItem) {
        root = newRoot
    }
}
