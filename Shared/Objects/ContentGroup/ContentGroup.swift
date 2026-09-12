//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import SwiftUI

// TODO: Relax `WithRefresh` requirement?

typealias ContentGroupBuilder = ArrayBuilder<any ContentGroup>

@MainActor
protocol ContentGroup<ViewModel>: Identifiable {

    associatedtype Body: View
    associatedtype ViewModel: WithRefresh

    var id: String { get }
    var viewModel: ViewModel { get }
    var _shouldBeResolved: Bool { get }

    /// Emit on the main actor to flag content, visibility, or provider changes.
    var refreshRequests: AnyPublisher<ContentGroupRefresh, Never> { get }

    @ViewBuilder
    func body(with viewModel: ViewModel) -> Body
}

extension ContentGroup {
    var refreshRequests: AnyPublisher<ContentGroupRefresh, Never> {
        Combine.Empty().eraseToAnyPublisher()
    }

    var _shouldBeResolved: Bool {
        true
    }
}

extension ContentGroup where ViewModel == Empty {
    var viewModel: Empty {
        .init()
    }
}
