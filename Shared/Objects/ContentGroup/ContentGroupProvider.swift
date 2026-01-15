//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

@MainActor
protocol ContentGroupProvider: Displayable {

    associatedtype Environment = Empty

    var id: String { get }
    var environment: Environment { get set }

    @ContentGroupBuilder
    func makeGroups(environment: Environment) async throws -> [any ContentGroup]
}

extension ContentGroupProvider where Environment == Empty {
    var environment: Empty {
        get { .init() }
        set {}
    }
}
