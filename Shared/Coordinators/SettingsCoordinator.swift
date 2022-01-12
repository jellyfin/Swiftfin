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

final class SettingsCoordinator: NavigationCoordinatable {

	let stack = NavigationStack(initial: \SettingsCoordinator.start)

	@Root
	var start = makeStart
	@Route(.push)
	var serverDetail = makeServerDetail
	@Route(.push)
	var overlaySettings = makeOverlaySettings
	@Route(.push)
	var experimentalSettings = makeExperimentalSettings
	@Route(.push)
	var missingSettings = makeMissingSettings

	@ViewBuilder
	func makeServerDetail() -> some View {
		let viewModel = ServerDetailViewModel(server: SessionManager.main.currentLogin.server)
		ServerDetailView(viewModel: viewModel)
	}

	@ViewBuilder
	func makeOverlaySettings() -> some View {
		OverlaySettingsView()
	}

	@ViewBuilder
	func makeExperimentalSettings() -> some View {
		ExperimentalSettingsView()
	}

	@ViewBuilder
	func makeMissingSettings() -> some View {
		MissingItemsSettingsView()
	}

	@ViewBuilder
	func makeStart() -> some View {
		let viewModel = SettingsViewModel(server: SessionManager.main.currentLogin.server, user: SessionManager.main.currentLogin.user)
		SettingsView(viewModel: viewModel)
	}
}
