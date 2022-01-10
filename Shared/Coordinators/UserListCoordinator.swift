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

final class UserListCoordinator: NavigationCoordinatable {

	let stack = NavigationStack(initial: \UserListCoordinator.start)

	@Root
	var start = makeStart
	@Route(.push)
	var userSignIn = makeUserSignIn
	@Route(.push)
	var serverDetail = makeServerDetail

	let viewModel: UserListViewModel

	init(viewModel: UserListViewModel) {
		self.viewModel = viewModel
	}

	func makeUserSignIn(server: SwiftfinStore.State.Server) -> UserSignInCoordinator {
		UserSignInCoordinator(viewModel: .init(server: server))
	}

	func makeServerDetail(server: SwiftfinStore.State.Server) -> ServerDetailCoordinator {
		ServerDetailCoordinator(viewModel: .init(server: server))
	}

	@ViewBuilder
	func makeStart() -> some View {
		UserListView(viewModel: viewModel)
	}
}
