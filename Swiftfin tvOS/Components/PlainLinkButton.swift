//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct PlainLinkButton: View {
	@Environment(\.isFocused)
	var envFocused: Bool
	@State
	var focused: Bool = false
	@State
	var label: String

	var body: some View {
		Text(label)
			.fontWeight(focused ? .bold : .regular)
			.foregroundColor(.blue)
			.onChange(of: envFocused) { envFocus in
				withAnimation(.linear(duration: 0.15)) {
					self.focused = envFocus
				}
			}
			.scaleEffect(focused ? 1.1 : 1)
	}
}
