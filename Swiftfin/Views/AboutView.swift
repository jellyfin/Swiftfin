//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct AboutView: View {

	var body: some View {
		List {
			Section {
				HStack {
					Spacer()

					VStack(alignment: .center) {
						AppIcon()
							.cornerRadius(11)
							.frame(width: 150, height: 150)

						// App name, not to be localized
						Text("Swiftfin")
							.fontWeight(.semibold)
							.font(.title2)
					}

					Spacer()
				}
				.listRowBackground(Color.clear)
			}

			Section {

				HStack {
					L10n.about.text
					Spacer()
					Text("\(UIApplication.appVersion ?? "--") (\(UIApplication.bundleVersion ?? "--"))")
						.foregroundColor(.secondary)
				}

				HStack {
					Image("github-logo")
						.renderingMode(.template)
						.resizable()
						.frame(width: 20, height: 20)
						.foregroundColor(.primary)
					Link(L10n.sourceCode,
					     destination: URL(string: "https://github.com/jellyfin/Swiftfin")!)
						.foregroundColor(.primary)

					Spacer()

					Image(systemName: "chevron.right")
						.foregroundColor(.secondary)
				}

				HStack {
					Image(systemName: "plus.circle.fill")
					Link(L10n.requestFeature,
					     destination: URL(string: "https://github.com/jellyfin/Swiftfin/issues")!)
						.foregroundColor(.primary)

					Spacer()

					Image(systemName: "chevron.right")
						.foregroundColor(.secondary)
				}

				HStack {
					Image(systemName: "xmark.circle.fill")
					Link(L10n.reportIssue,
					     destination: URL(string: "https://github.com/jellyfin/Swiftfin/issues")!)
						.foregroundColor(.primary)

					Spacer()

					Image(systemName: "chevron.right")
						.foregroundColor(.secondary)
				}
			}
		}
	}
}
