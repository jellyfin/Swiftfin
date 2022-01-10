//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Foundation

public extension URL {
	/// Dictionary of the URL's query parameters
	var queryParameters: [String: String]? {
		guard let components = URLComponents(url: self, resolvingAgainstBaseURL: false),
		      let queryItems = components.queryItems else { return nil }

		var items: [String: String] = [:]

		for queryItem in queryItems {
			items[queryItem.name] = queryItem.value
		}

		return items
	}
}
