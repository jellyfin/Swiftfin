//
/*
 * SwiftFin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import Foundation
import Stinsen
import SwiftUI

typealias FilterCoordinatorParams = (filters: Binding<LibraryFilters>, enabledFilterType: [FilterType], parentId: String)

final class FilterCoordinator: NavigationCoordinatable {
    
    let stack = NavigationStack(initial: \FilterCoordinator.start)
    
    @Root var start = makeStart

    @Binding var filters: LibraryFilters
    var enabledFilterType: [FilterType]
    var parentId: String = ""

    init(filters: Binding<LibraryFilters>, enabledFilterType: [FilterType], parentId: String) {
        _filters = filters
        self.enabledFilterType = enabledFilterType
        self.parentId = parentId
    }

    @ViewBuilder func makeStart() -> some View {
        LibraryFilterView(filters: $filters, enabledFilterType: enabledFilterType, parentId: parentId)
    }
}
