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

final class SearchCoordinator: NavigationCoordinatable {

	let stack = NavigationStack(initial: \SearchCoordinator.start)

	@Root
	var start = makeStart
	@Route(.push)
	var item = makeItem

	let viewModel: LibrarySearchViewModel

	init(viewModel: LibrarySearchViewModel) {
		self.viewModel = viewModel
	}

	func makeItem(item: BaseItemDto) -> ItemCoordinator {
		ItemCoordinator(item: item)
	}

	@ViewBuilder
	func makeStart() -> some View {
		LibrarySearchView(viewModel: self.viewModel)
	}
}
