//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct NextUpCard: View {

	@EnvironmentObject
	var homeRouter: HomeCoordinator.Router
	let item: BaseItemDto

	var body: some View {
		VStack(alignment: .leading) {
			Button {
				homeRouter.route(to: \.modalItem, item)
			} label: {
				if item.itemType == .episode {
					ImageView(src: item.getSeriesBackdropImage(maxWidth: 500))
						.frame(width: 500, height: 281.25)
				} else {
					ImageView(src: item.getBackdropImage(maxWidth: 500))
						.frame(width: 500, height: 281.25)
				}
			}
			.buttonStyle(CardButtonStyle())
			.padding(.top)

			VStack(alignment: .leading) {
				Text("\(item.seriesName ?? item.name ?? "")")
					.font(.callout)
					.fontWeight(.semibold)
					.foregroundColor(.primary)
					.lineLimit(1)

				if item.itemType == .episode {
					Text(item.getEpisodeLocator() ?? "")
						.font(.callout)
						.fontWeight(.medium)
						.foregroundColor(.secondary)
						.lineLimit(1)
				}
			}
		}
	}
}
