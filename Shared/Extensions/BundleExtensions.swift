//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Foundation

extension Bundle {
	var iconFileName: String? {
		guard let icons = infoDictionary?["CFBundleIcons"] as? [String: Any],
		      let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
		      let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
		      let iconFileName = iconFiles.last
		else { return nil }
		return iconFileName
	}
}
