//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

typealias ContentGroupBuilder = ArrayBuilder<any _ContentGroup>

@MainActor
protocol _ContentGroup<ViewModel>: Identifiable {

    associatedtype Body: View
    associatedtype ViewModel: WithRefresh

    var id: String { get }
    var viewModel: ViewModel { get }

    @ViewBuilder
    func body(with viewModel: ViewModel) -> Body
}

extension _ContentGroup where ViewModel == Empty {
    var viewModel: Empty { .init() }
}
