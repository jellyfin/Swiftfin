//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Combine
import SwiftUI

struct TabItemSelected {

    struct Event {
        let isRoot: Bool
        let isRepeat: Bool
    }

    var events: AnyPublisher<Event, Never> {
        eventSubject
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }

    // TODO: should be private
    var eventSubject: PassthroughSubject<Event, Never> = .init()
}

extension EnvironmentValues {

    @Entry
    var tabItemSelectedEvent: TabItemSelected = .init()
}
