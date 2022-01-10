//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation

enum OverlayType: String, CaseIterable, Defaults.Serializable {
	case normal
	case compact

	var label: String {
		switch self {
		case .normal:
			return "Normal"
		case .compact:
			return "Compact"
		}
	}
}
