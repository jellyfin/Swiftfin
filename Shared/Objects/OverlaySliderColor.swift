//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Defaults
import UIKit

enum OverlaySliderColor: String, CaseIterable, DefaultsSerializable {
	case white
	case jellyfinPurple

	var displayLabel: String {
		switch self {
		case .white:
			return "White"
		case .jellyfinPurple:
			return "Jellyfin Purple"
		}
	}
}
