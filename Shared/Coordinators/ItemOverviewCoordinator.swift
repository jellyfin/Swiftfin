//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import Stinsen
import SwiftUI

final class ItemOverviewCoordinator: NavigationCoordinatable {

	let stack = NavigationStack(initial: \ItemOverviewCoordinator.start)

	@Root
	var start = makeStart

	let item: BaseItemDto

	init(item: BaseItemDto) {
		self.item = item
	}

	@ViewBuilder
	func makeStart() -> some View {
		#if os(tvOS)
			EmptyView()
		#else
			ItemOverviewView(item: item)
		#endif
	}
}
