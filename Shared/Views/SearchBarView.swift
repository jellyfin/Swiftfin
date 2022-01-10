//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct SearchBar: View {
	@Binding
	var text: String

	@State
	private var isEditing = false

	var body: some View {
		HStack(spacing: 8) {
			TextField(L10n.searchDots, text: $text)
				.padding(8)
				.padding(.horizontal, 16)
			#if os(iOS)
				.background(Color(.systemGray6))
			#endif
				.cornerRadius(8)
			if !text.isEmpty {
				Button(action: {
					self.text = ""
				}) {
					Image(systemName: "xmark.circle.fill")
						.foregroundColor(.secondary)
				}
			}
		}
		.padding(.horizontal, 16)
	}
}
