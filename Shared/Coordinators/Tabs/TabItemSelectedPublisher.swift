//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension TabCoordinator {

    typealias TabItemSelectedPublisher = LegacyEventPublisher<TabCoordinator.SelectedEvent>
}

@propertyWrapper
struct TabItemSelected: DynamicProperty {

    @Environment(\.tabItemSelected)
    private var publisher

    var wrappedValue: TabCoordinator.TabItemSelectedPublisher {
        publisher
    }
}

extension EnvironmentValues {

    @Entry
    var tabItemSelected: TabCoordinator.TabItemSelectedPublisher = .init()
}
