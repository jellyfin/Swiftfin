//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

public extension Color {

	internal static let jellyfinPurple = Color(uiColor: .jellyfinPurple)

	#if os(tvOS) // tvOS doesn't have these
		static let systemFill = Color(UIColor.white)
		static let secondarySystemFill = Color(UIColor.gray)
		static let tertiarySystemFill = Color(UIColor.black)
		static let lightGray = Color(UIColor.lightGray)
	#else
		static let systemFill = Color(UIColor.systemFill)
		static let systemBackground = Color(UIColor.systemBackground)
		static let secondarySystemFill = Color(UIColor.secondarySystemBackground)
		static let tertiarySystemFill = Color(UIColor.tertiarySystemBackground)
	#endif
}

extension UIColor {
	static let jellyfinPurple = UIColor(red: 172 / 255, green: 92 / 255, blue: 195 / 255, alpha: 1)
}
