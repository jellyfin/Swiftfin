//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct PrimaryButtonView: View {

	private let title: String
	private let action: () -> Void

	init(title: String, _ action: @escaping () -> Void) {
		self.title = title
		self.action = action
	}

	var body: some View {
		Button {
			action()
		} label: {
			ZStack {
				Rectangle()
					.foregroundColor(Color(UIColor.systemPurple))
					.frame(maxWidth: 400, maxHeight: 50)
					.frame(height: 50)
					.cornerRadius(10)
					.padding(.horizontal, 30)
					.padding([.top, .bottom], 20)

				Text(title)
					.foregroundColor(Color.white)
					.bold()
			}
		}
	}
}
