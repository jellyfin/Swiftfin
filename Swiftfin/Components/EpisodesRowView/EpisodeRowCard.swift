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
		Button {
			itemRouter.route(to: \.item, episode)
		} label: {
			HStack(alignment: .top) {
				VStack(alignment: .leading) {

					ImageView(src: episode.getBackdropImage(maxWidth: 200),
					          bh: episode.getBackdropImageBlurHash())
						.mask(Rectangle().frame(width: 200, height: 112).cornerRadius(10))
						.frame(width: 200, height: 112)
						.overlay {
							if episode.id == viewModel.item.id {
								RoundedRectangle(cornerRadius: 6)
									.stroke(Color.jellyfinPurple, lineWidth: 4)
							}
						}
						.padding(.top)

					VStack(alignment: .leading) {
						Text(episode.getEpisodeLocator() ?? "S-:E-")
							.font(.footnote)
							.foregroundColor(.secondary)
						Text(episode.name ?? L10n.noTitle)
							.font(.body)
							.padding(.bottom, 1)
							.lineLimit(2)

						if episode.unaired {
							Text(episode.airDateLabel ?? L10n.noOverviewAvailable)
								.font(.caption)
								.foregroundColor(.secondary)
								.fontWeight(.light)
								.lineLimit(3)
						} else {
							Text(episode.overview ?? "")
								.font(.caption)
								.foregroundColor(.secondary)
								.fontWeight(.light)
								.lineLimit(3)
						}
					}

					Spacer()
				}
				.frame(width: 200)
				.shadow(radius: 4, y: 2)
			}
		}
		.buttonStyle(PlainButtonStyle())
	}
}
