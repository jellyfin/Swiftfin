//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine

@MainActor
protocol ContentGroupProvider: Displayable, Identifiable {

    associatedtype Environment = Empty

    var environment: Environment { get set }
    var id: String { get }

    /// Emit on the main actor; `.groups` rebuilds the candidates using `makeGroups`.
    var refreshRequests: AnyPublisher<ContentGroupRefresh, Never> { get }

    @ContentGroupBuilder
    func makeGroups(environment: Environment) async throws -> [any ContentGroup]
}

extension ContentGroupProvider {
    var refreshRequests: AnyPublisher<ContentGroupRefresh, Never> {
        Combine.Empty().eraseToAnyPublisher()
    }
}

extension ContentGroupProvider where Environment == Empty {
    var environment: Empty {
        get { .init() }
        set {}
    }
}
