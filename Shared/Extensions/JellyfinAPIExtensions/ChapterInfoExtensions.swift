//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

extension ChapterInfo {

	var timestampLabel: String {
		let seconds = (startPositionTicks ?? 0) / 10_000_000
		return seconds.toReadableString()
	}
}

extension Int64 {

	func toReadableString() -> String {

		let s = Int(self) % 60
		let mn = (Int(self) / 60) % 60
		let hr = (Int(self) / 3600)

		var final = ""

		if hr != 0 {
			final += "\(hr):"
		}

		if mn != 0 {
			final += String(format: "%0.2d:", mn)
		} else {
			final += "00:"
		}

		final += String(format: "%0.2d", s)

		return final
	}
}
