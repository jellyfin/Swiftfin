//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Defaults
import Stinsen
import SwiftUI

struct BasicAppSettingsView: View {

	@EnvironmentObject
	var basicAppSettingsRouter: BasicAppSettingsCoordinator.Router
	@ObservedObject
	var viewModel: BasicAppSettingsViewModel
	@State
	var resetTapped: Bool = false

	@Default(.appAppearance)
	var appAppearance

	var body: some View {
		Form {

			Section {
				Button {} label: {
					HStack {
						L10n.version.text
						Spacer()
						Text("\(UIApplication.appVersion ?? "--") (\(UIApplication.bundleVersion ?? "--"))")
							.foregroundColor(.secondary)
					}
				}
			} header: {
				L10n.about.text
			}

			// TODO: Implement once design is theme appearance friendly
//			Section {
//				Picker(L10n.appearance, selection: $appAppearance) {
//					ForEach(self.viewModel.appearances, id: \.self) { appearance in
//						Text(appearance.localizedName).tag(appearance.rawValue)
//					}
//				}
//			} header: {
//				L10n.accessibility.text
//			}

			Button {
				resetTapped = true
			} label: {
				L10n.reset.text
			}
		}
		.alert(L10n.reset, isPresented: $resetTapped, actions: {
			Button(role: .destructive) {
				viewModel.resetAppSettings()
				basicAppSettingsRouter.dismissCoordinator()
			} label: {
				L10n.reset.text
			}
		})
		.navigationTitle(L10n.settings)
	}
}
