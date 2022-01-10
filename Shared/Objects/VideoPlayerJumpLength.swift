//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Defaults
import UIKit

enum VideoPlayerJumpLength: Int32, CaseIterable, Defaults.Serializable {
	case thirty = 30
	case fifteen = 15
	case ten = 10
	case five = 5

	var label: String {
		"\(self.rawValue) seconds"
	}

	var shortLabel: String {
		"\(self.rawValue)s"
	}

	var forwardImageLabel: String {
		switch self {
		case .thirty:
			return "goforward.30"
		case .fifteen:
			return "goforward.15"
		case .ten:
			return "goforward.10"
		case .five:
			return "goforward.5"
		}
	}

	var backwardImageLabel: String {
		switch self {
		case .thirty:
			return "gobackward.30"
		case .fifteen:
			return "gobackward.15"
		case .ten:
			return "gobackward.10"
		case .five:
			return "gobackward.5"
		}
	}
}
