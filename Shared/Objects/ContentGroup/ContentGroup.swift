//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

typealias ContentGroupBuilder = ArrayBuilder<any ContentGroup>

@MainActor
protocol ContentGroup<ViewModel>: Identifiable {

    associatedtype Body: View
    associatedtype ViewModel: WithRefresh

    var id: String { get }
    var viewModel: ViewModel { get }
    var _shouldBeResolved: Bool { get }

    @ViewBuilder
    func body(with viewModel: ViewModel) -> Body
}

extension ContentGroup {
    var _shouldBeResolved: Bool {
        true
    }
}

extension ContentGroup where ViewModel == Empty {
    var viewModel: Empty {
        .init()
    }
}
