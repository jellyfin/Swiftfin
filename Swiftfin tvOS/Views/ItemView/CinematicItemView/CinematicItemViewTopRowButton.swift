//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct CinematicItemViewTopRowButton<Content: View>: View {
	@Environment(\.isFocused)
	var envFocused: Bool
	@State
	var focused: Bool = false
	@State
	var wrappedScrollView: UIScrollView?
	var content: () -> Content

	@FocusState
	private var buttonFocused: Bool

	var body: some View {
		content()
			.focused($buttonFocused)
			.onChange(of: envFocused) { envFocus in
				if envFocus == true {
					wrappedScrollView?.scrollToTop()
					DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
						wrappedScrollView?.scrollToTop()
					}
				}

				withAnimation(.linear(duration: 0.15)) {
					self.focused = envFocus
				}
			}
			.onChange(of: buttonFocused) { newValue in
				if newValue {
					wrappedScrollView?.scrollToTop()
					DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
						wrappedScrollView?.scrollToTop()
					}

					withAnimation(.linear(duration: 0.15)) {
						self.focused = newValue
					}
				}
			}
	}
}
