//
// SwiftFin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2021 Jellyfin & Jellyfin Contributors
//

import SwiftUI

public extension Color {

	internal static let jellyfinPurple = Color(red: 172 / 255, green: 92 / 255, blue: 195 / 255)

	#if os(tvOS) // tvOS doesn't have these
		static let systemFill = Color(UIColor.white)
		static let secondarySystemFill = Color(UIColor.gray)
		static let tertiarySystemFill = Color(UIColor.black)
	#else
		static let systemFill = Color(UIColor.systemFill)
		static let secondarySystemFill = Color(UIColor.secondarySystemBackground)
		static let tertiarySystemFill = Color(UIColor.tertiarySystemBackground)
	#endif
}
