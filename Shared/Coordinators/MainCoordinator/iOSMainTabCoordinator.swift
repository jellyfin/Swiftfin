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

final class MainTabCoordinator: TabCoordinatable {
	var child = TabChild(startingItems: [
		\MainTabCoordinator.home,
		\MainTabCoordinator.allMedia,
	])

	@Route(tabItem: makeHomeTab, onTapped: onHomeTapped)
	var home = makeHome
	@Route(tabItem: makeAllMediaTab, onTapped: onMediaTapped)
	var allMedia = makeAllMedia

	func makeHome() -> NavigationViewCoordinator<HomeCoordinator> {
		NavigationViewCoordinator(HomeCoordinator())
	}

	func onHomeTapped(isRepeat: Bool, coordinator: NavigationViewCoordinator<HomeCoordinator>) {
		if isRepeat {
			coordinator.child.popToRoot()
		}
	}

	@ViewBuilder
	func makeHomeTab(isActive: Bool) -> some View {
		Image(systemName: "house")
		L10n.home.text
	}

	func makeAllMedia() -> NavigationViewCoordinator<LibraryListCoordinator> {
		NavigationViewCoordinator(LibraryListCoordinator(viewModel: LibraryListViewModel()))
	}

	func onMediaTapped(isRepeat: Bool, coordinator: NavigationViewCoordinator<LibraryListCoordinator>) {
		if isRepeat {
			coordinator.child.popToRoot()
		}
	}

	@ViewBuilder
	func makeAllMediaTab(isActive: Bool) -> some View {
		Image(systemName: "folder")
		L10n.allMedia.text
	}

	@ViewBuilder
	func customize(_ view: AnyView) -> some View {
		view.onAppear {
			AppURLHandler.shared.appURLState = .allowed
			// TODO: todo
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
				AppURLHandler.shared.processLaunchedURLIfNeeded()
			}
		}
	}
}
