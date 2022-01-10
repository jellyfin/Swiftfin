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
	var resetUserSettingsTapped: Bool = false
	@State
	var resetAppSettingsTapped: Bool = false
	@State
	var removeAllUsersTapped: Bool = false

	@Default(.appAppearance)
	var appAppearance
	@Default(.defaultHTTPScheme)
	var defaultHTTPScheme

	var body: some View {
		Form {
			Section {
				Picker(L10n.appearance, selection: $appAppearance) {
					ForEach(self.viewModel.appearances, id: \.self) { appearance in
						Text(appearance.localizedName).tag(appearance.rawValue)
					}
				}
			} header: {
				L10n.accessibility.text
			}

			Section {
				Picker("Default Scheme", selection: $defaultHTTPScheme) {
					ForEach(HTTPScheme.allCases, id: \.self) { scheme in
						Text("\(scheme.rawValue)")
					}
				}
			} header: {
				Text("Networking")
			}

			Button {
				resetUserSettingsTapped = true
			} label: {
				Text("Reset User Settings")
			}

			Button {
				resetAppSettingsTapped = true
			} label: {
				Text("Reset App Settings")
			}

			Button {
				removeAllUsersTapped = true
			} label: {
				Text("Remove All Users")
			}
		}
		.alert("Reset User Settings", isPresented: $resetUserSettingsTapped, actions: {
			Button(role: .destructive) {
				viewModel.resetUserSettings()
			} label: {
				L10n.reset.text
			}
		})
		.alert("Reset App Settings", isPresented: $resetAppSettingsTapped, actions: {
			Button(role: .destructive) {
				viewModel.resetAppSettings()
			} label: {
				L10n.reset.text
			}
		})
		.alert("Remove All Users", isPresented: $removeAllUsersTapped, actions: {
			Button(role: .destructive) {
				viewModel.removeAllUsers()
			} label: {
				L10n.reset.text
			}
		})
		.navigationBarTitle("Settings", displayMode: .inline)
		.toolbar {
			ToolbarItemGroup(placement: .navigationBarLeading) {
				Button {
					basicAppSettingsRouter.dismissCoordinator()
				} label: {
					Image(systemName: "xmark.circle.fill")
				}
			}
		}
	}
}
