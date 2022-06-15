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

final class TVLibrariesCoordinator: NavigationCoordinatable {

	let stack = NavigationStack(initial: \TVLibrariesCoordinator.start)

	@Root
	var start = makeStart
	@Root
	var rootLibrary = makeRootLibrary
	@Route(.push)
	var library = makeLibrary

	let viewModel: TVLibrariesViewModel
	let title: String

	init(viewModel: TVLibrariesViewModel, title: String) {
		self.viewModel = viewModel
		self.title = title
	}

	@ViewBuilder
	func makeStart() -> some View {
		TVLibrariesView(viewModel: self.viewModel, title: title)
	}

	func makeLibrary(library: BaseItemDto) -> LibraryCoordinator {
		LibraryCoordinator(viewModel: LibraryViewModel(parentID: library.id), title: library.title)
	}

	func makeRootLibrary(library: BaseItemDto) -> LibraryCoordinator {
		LibraryCoordinator(viewModel: LibraryViewModel(parentID: library.id), title: library.title)
	}
}
