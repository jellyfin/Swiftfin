//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Combine
import Factory
import Foundation

class ViewModel: ObservableObject {

    @Injected(LogManager.service)
    var logger

    @Injected(Container.userSession)
    var userSession

    // TODO: remove on transition to Stateful
    @Published
    var error: ErrorMessage? = nil

    // TODO: remove on transition to Stateful
    @Published
    var isLoading = false

    var cancellables = Set<AnyCancellable>()

    init() {}
}
