//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import Stinsen
import SwiftUI

final class FilterCoordinator: NavigationCoordinatable {

    struct Parameters {
        let title: String
        let viewModel: FilterViewModel
        let filter: WritableKeyPath<ItemFilters, [ItemFilters.Filter]>
        let selectorType: SelectorType
    }

    let stack = NavigationStack(initial: \FilterCoordinator.start)

    @Root
    var start = makeStart

    private let parameters: Parameters

    init(parameters: Parameters) {
        self.parameters = parameters
    }

    @ViewBuilder
    func makeStart() -> some View {
        #if os(tvOS)
        Text(verbatim: .emptyDash)
        #else
        FilterView(
            title: parameters.title,
            viewModel: parameters.viewModel,
            filter: parameters.filter,
            selectorType: parameters.selectorType
        )
        #endif
    }
}
