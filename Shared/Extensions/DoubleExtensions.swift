//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Foundation

extension Double {

	func subtract(_ other: Double, floor: Double) -> Double {
		var v = self - other

		if v < floor {
			v += abs(floor - v)
		}

		return v
	}
}
