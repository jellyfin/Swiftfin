//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import Stinsen
import SwiftUI

final class FilterCoordinator: NavigationCoordinatable {

    let stack = NavigationStack(initial: \FilterCoordinator.start)

    @Root
    var start = makeStart

    private let title: String
    private var viewModel: FilterViewModel
    private let filter: WritableKeyPath<ItemFilters, [ItemFilters.Filter]>
    private let singleSelect: Bool

    init(
        title: String,
        viewModel: FilterViewModel,
        filter: WritableKeyPath<ItemFilters, [ItemFilters.Filter]>,
        singleSelect: Bool
    ) {
        self.title = title
        self.viewModel = viewModel
        self.filter = filter
        self.singleSelect = singleSelect
    }

    @ViewBuilder
    func makeStart() -> some View {
        FilterView(
            title: title,
            viewModel: viewModel,
            filter: filter,
            singleSelect: singleSelect
        )
    }
}
