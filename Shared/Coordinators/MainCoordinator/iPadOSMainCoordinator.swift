//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Foundation
import Stinsen
import SwiftUI

final class iPadOSMainCoordinator: SideBarCoordinatable {
	var child = SideBarChild(startingItems: [
		\iPadOSMainCoordinator.home,
		\iPadOSMainCoordinator.second,
	])

	@SideBarRoute(sideBarItem: makeHomeTab)
	var home = makeHome
	@SideBarRoute(sideBarItem: makeSecondTab)
	var second = makeSecond

	func makeHome() -> NavigationViewCoordinator<HomeCoordinator> {
		NavigationViewCoordinator(HomeCoordinator())
	}

	@ViewBuilder
	func makeHomeTab(isActive: Bool) -> some View {
		if isActive {
			Label("Home", systemImage: "house.fill")
		} else {
			Label("Home", systemImage: "house")
		}
	}

	@ViewBuilder
	func makeSecond() -> some View {
		Color.red
	}

	@ViewBuilder
	func makeSecondTab(isActive: Bool) -> some View {
		Label("Second", systemImage: "info.circle")
	}
}
