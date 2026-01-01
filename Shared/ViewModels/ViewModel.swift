//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Factory
import Foundation
import KeychainSwift
import Logging

class ViewModel: ObservableObject {

    @Injected(\.dataStore)
    var dataStack

    @Injected(\.keychainService)
    var keychain

    let logger = Logger.swiftfin()

    /// The current *signed in* user session
    @Injected(\.currentUserSession)
    var userSession: UserSession!

    var cancellables = Set<AnyCancellable>()

    private var userSessionResolverCancellable: AnyCancellable?

    init() {
        userSessionResolverCancellable = Notifications[.didChangeCurrentServerURL]
            .publisher
            .sink { [weak self] _ in
                self?.$userSession.resolve(reset: .scope)
            }
    }
}
