//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

struct Empty {}

extension Empty: LibraryGrouping {
    var displayTitle: String { "" }
    var id: String { "" }
}

extension Empty: WithDefaultValue {
    static var `default`: Empty = .init()
}

extension Empty: WithRefresh {
    func refresh() {}
    func refresh() async throws {}
}
