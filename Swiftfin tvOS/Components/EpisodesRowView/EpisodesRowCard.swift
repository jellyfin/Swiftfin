//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct EpisodeRowCard: View {

	@EnvironmentObject
	var itemRouter: ItemCoordinator.Router
	let viewModel: EpisodesRowManager
	let episode: BaseItemDto

	var body: some View {
		VStack {
			Button {
				itemRouter.route(to: \.item, episode)
			} label: {
				ImageView(src: episode.getBackdropImage(maxWidth: 550),
				          bh: episode.getBackdropImageBlurHash())
					.mask(Rectangle().frame(width: 550, height: 308))
					.frame(width: 550, height: 308)
			}
			.buttonStyle(CardButtonStyle())

			VStack(alignment: .leading) {

				VStack(alignment: .leading) {
					Text(episode.getEpisodeLocator() ?? "")
						.font(.caption)
						.foregroundColor(.secondary)
					Text(episode.name ?? "")
						.font(.footnote)
						.padding(.bottom, 1)

					if episode.unaired {
						Text(episode.airDateLabel ?? L10n.noOverviewAvailable)
							.font(.caption)
							.foregroundColor(.secondary)
							.fontWeight(.light)
							.lineLimit(3)
					} else {
						Text(episode.overview ?? "")
							.font(.caption)
							.fontWeight(.light)
							.lineLimit(4)
							.fixedSize(horizontal: false, vertical: true)
					}
				}

				Spacer()
			}
			.padding()
			.frame(width: 550)
		}
		.focusSection()
	}
}
