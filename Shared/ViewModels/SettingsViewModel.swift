//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation
import JellyfinAPI
import Stinsen
import SwiftUI

final class SettingsViewModel: ViewModel {

	@RouterObject
	var router: SettingsCoordinator.Router?

	var bitrates: [Bitrates] = []
	var langs: [TrackLanguage] = []

	let server: SwiftfinStore.State.Server
	let user: SwiftfinStore.State.User

	@Published
	var quickConnectCode = ""

	@Published
	var validQuickConnect = true

	init(server: SwiftfinStore.State.Server, user: SwiftfinStore.State.User) {

		self.server = server
		self.user = user

		// Bitrates
		let url = Bundle.main.url(forResource: "bitrates", withExtension: "json")!

		do {
			let jsonData = try Data(contentsOf: url, options: .mappedIfSafe)
			do {
				self.bitrates = try JSONDecoder().decode([Bitrates].self, from: jsonData)
			} catch {
				LogManager.log.error("Error converting processed JSON into Swift compatible schema.")
			}
		} catch {
			LogManager.log.error("Error processing JSON file `bitrates.json`")
		}

		// Track languages
		self.langs = Locale.isoLanguageCodes.compactMap {
			guard let name = Locale.current.localizedString(forLanguageCode: $0) else { return nil }
			return TrackLanguage(name: name, isoCode: $0)
		}.sorted(by: { $0.name < $1.name })
		self.langs.insert(.auto, at: 0)
	}

	func sendQuickConnect() {
		QuickConnectAPI.authorize(code: self.quickConnectCode)
			.sink(receiveCompletion: { completion in
				switch completion {
				case .failure:
					LogManager.log.debug("Invalid Quick Connect code entered")
					self.validQuickConnect = false
				default:
					self.handleAPIRequestError(displayMessage: "Error", completion: completion)
				}
			}, receiveValue: { value in
				if !value {
					LogManager.log.debug("Invalid Quick Connect code entered")
					self.validQuickConnect = false
				} else {
					LogManager.log.debug("Valid Quick connect code entered")
					self.router?.dismissCoordinator()
				}
			})
			.store(in: &cancellables)
	}
}
