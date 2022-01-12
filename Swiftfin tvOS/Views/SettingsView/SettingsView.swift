//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import CoreData
import Defaults
import JellyfinAPI
import SwiftUI

struct SettingsView: View {

	@EnvironmentObject
	var settingsRouter: SettingsCoordinator.Router
	@ObservedObject
	var viewModel: SettingsViewModel

	@Default(.autoSelectAudioLangCode)
	var autoSelectAudioLangcode
	@Default(.videoPlayerJumpForward)
	var jumpForwardLength
	@Default(.videoPlayerJumpBackward)
	var jumpBackwardLength
	@Default(.downActionShowsMenu)
	var downActionShowsMenu
	@Default(.confirmClose)
	var confirmClose
	@Default(.tvOSCinematicViews)
	var tvOSCinematicViews
	@Default(.showPosterLabels)
	var showPosterLabels
	@Default(.resumeOffset)
	var resumeOffset
	@Default(.subtitleSize)
	var subtitleSize

	var body: some View {
		GeometryReader { reader in
			HStack {

				Image(uiImage: UIImage(named: "App Icon")!)
					.cornerRadius(30)
					.scaleEffect(2)
					.frame(width: reader.size.width / 2)

				Form {
					Section(header: EmptyView()) {

						Button {} label: {
							HStack {
								L10n.user.text
								Spacer()
								Text(viewModel.user.username)
									.foregroundColor(.jellyfinPurple)
							}
						}

						Button {
							settingsRouter.route(to: \.serverDetail)
						} label: {
							HStack {
								L10n.server.text
									.foregroundColor(.primary)
								Spacer()
								Text(viewModel.server.name)
									.foregroundColor(.jellyfinPurple)

								Image(systemName: "chevron.right")
									.foregroundColor(.jellyfinPurple)
							}
						}

						Button {
							SessionManager.main.logout()
						} label: {
							L10n.switchUser.text
								.foregroundColor(Color.jellyfinPurple)
								.font(.callout)
						}
					}

					Section(header: L10n.videoPlayer.text) {
						Picker(L10n.jumpForwardLength, selection: $jumpForwardLength) {
							ForEach(VideoPlayerJumpLength.allCases, id: \.self) { length in
								Text(length.label).tag(length.rawValue)
							}
						}

						Picker(L10n.jumpBackwardLength, selection: $jumpBackwardLength) {
							ForEach(VideoPlayerJumpLength.allCases, id: \.self) { length in
								Text(length.label).tag(length.rawValue)
							}
						}

						Toggle(L10n.resume5SecondOffset, isOn: $resumeOffset)

						Toggle(L10n.pressDownForMenu, isOn: $downActionShowsMenu)

						Toggle(L10n.confirmClose, isOn: $confirmClose)

						Button {
							settingsRouter.route(to: \.overlaySettings)
						} label: {
							HStack {
								L10n.overlay.text
									.foregroundColor(.primary)
								Spacer()
								Image(systemName: "chevron.right")
							}
						}

						Button {
							settingsRouter.route(to: \.experimentalSettings)
						} label: {
							HStack {
								L10n.experimental.text
									.foregroundColor(.primary)
								Spacer()
								Image(systemName: "chevron.right")
							}
						}
					}

					Section {
						Toggle(L10n.cinematicViews, isOn: $tvOSCinematicViews)
					} header: {
						L10n.appearance.text
					}

					Section(header: L10n.accessibility.text) {
						Toggle(L10n.showPosterLabels, isOn: $showPosterLabels)

						Button {
							settingsRouter.route(to: \.missingSettings)
						} label: {
							HStack {
								L10n.missingItems.text
									.foregroundColor(.primary)
								Spacer()
								Image(systemName: "chevron.right")
							}
						}

						Picker(L10n.subtitleSize, selection: $subtitleSize) {
							ForEach(SubtitleSize.allCases, id: \.self) { size in
								Text(size.label).tag(size.rawValue)
							}
						}
					}
				}
			}
		}
	}
}

struct SettingsView_Previews: PreviewProvider {
	static var previews: some View {
		SettingsView(viewModel: SettingsViewModel(server: .sample, user: .sample))
	}
}
