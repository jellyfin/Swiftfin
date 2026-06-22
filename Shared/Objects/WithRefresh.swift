//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

@MainActor
protocol WithRefresh {

    associatedtype Background: WithRefresh = Empty

    var background: Background { get set }

    func refresh()
    func refresh() async
}

extension WithRefresh where Background == Empty {

    var background: Empty {
        get { .init() }
        set {}
    }
}
