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
import UIKit

struct AuthHeaderBuilder {
	func setAuthHeader(accessToken: String) {
		let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
		var deviceName = UIDevice.current.name
		deviceName = deviceName.folding(options: .diacriticInsensitive, locale: .current)
		deviceName = String(deviceName.unicodeScalars.filter { CharacterSet.urlQueryAllowed.contains($0) })

		let platform: String
		#if os(tvOS)
			platform = "tvOS"
		#else
			platform = "iOS"
		#endif

		var header = "MediaBrowser "
		header.append("Client=\"Jellyfin \(platform)\", ")
		header.append("Device=\"\(deviceName)\", ")
		header.append("DeviceId=\"\(platform)_\(UIDevice.vendorUUIDString)_\(String(Date().timeIntervalSince1970))\", ")
		header.append("Version=\"\(appVersion ?? "0.0.1")\", ")
		header.append("Token=\"\(accessToken)\"")

		JellyfinAPIAPI.customHeaders["X-Emby-Authorization"] = header
	}
}
