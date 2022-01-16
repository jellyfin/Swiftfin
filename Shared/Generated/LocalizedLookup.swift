//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Foundation

class TranslationService {

	static let shared = TranslationService()

	func lookupTranslation(forKey key: String, inTable table: String) -> String {

		let expectedValue = Bundle.main.localizedString(forKey: key, value: nil, table: table)

		if expectedValue == key || NSLocale.preferredLanguages.first == "en" {
			guard let path = Bundle.main.path(forResource: "en", ofType: "lproj"),
			      let bundle = Bundle(path: path) else { return expectedValue }

			return NSLocalizedString(key, bundle: bundle, comment: "")
		} else {
			return expectedValue
		}
	}
}
