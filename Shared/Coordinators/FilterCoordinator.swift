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

typealias FilterCoordinatorParams = (libraryItem: BaseItemDto, filters: Binding<LibraryFilters>, enabledFilterType: [FilterType])

final class FilterCoordinator: NavigationCoordinatable {

	let stack = NavigationStack(initial: \FilterCoordinator.start)

	@Root
	var start = makeStart

    let libraryItem: BaseItemDto
	@Binding
	var filters: LibraryFilters
	var enabledFilterType: [FilterType]

    init(libraryItem: BaseItemDto, filters: Binding<LibraryFilters>, enabledFilterType: [FilterType]) {
        self.libraryItem =  libraryItem
		_filters = filters
		self.enabledFilterType = enabledFilterType
	}

	@ViewBuilder
	func makeStart() -> some View {
        LibraryFilterView(filters: $filters, enabledFilterType: enabledFilterType, parentId: libraryItem.id!)
	}
}
