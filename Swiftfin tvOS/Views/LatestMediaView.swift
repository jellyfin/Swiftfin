//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

struct LatestMediaView: View {

	@EnvironmentObject
	var homeRouter: HomeCoordinator.Router
	@StateObject
	var viewModel: LatestMediaViewModel
	@Default(.showPosterLabels)
	var showPosterLabels

	var body: some View {
		VStack(alignment: .leading) {

			L10n.latestWithString(viewModel.library.name ?? "").text
				.font(.title3)
				.padding(.horizontal, 50)

			ScrollView(.horizontal) {
				HStack(alignment: .top) {
					ForEach(viewModel.items, id: \.self) { item in

						VStack(spacing: 15) {
							Button {
								homeRouter.route(to: \.modalItem, item)
							} label: {
								ImageView(src: item.portraitHeaderViewURL(maxWidth: 257))
									.frame(width: 257, height: 380)
							}
							.frame(height: 380)
							.buttonStyle(PlainButtonStyle())

							if showPosterLabels {
								Text(item.title)
									.lineLimit(2)
									.frame(width: 257)
							}
						}
					}

					Button {
						homeRouter.route(to: \.library, (viewModel: .init(parentID: viewModel.library.id!,
						                                                  filters: LibraryFilters(filters: [], sortOrder: [.descending],
						                                                                          sortBy: [.dateAdded])),
						                                 title: viewModel.library.name ?? ""))
					} label: {
						ZStack {
							Color(UIColor.darkGray)
								.opacity(0.5)

							VStack(spacing: 20) {
								Image(systemName: "chevron.right")
									.font(.title)

								L10n.seeAll.text
									.font(.title3)
							}
						}
					}
					.frame(width: 257, height: 380)
					.buttonStyle(PlainButtonStyle())
				}
				.padding(.horizontal, 50)
				.padding(.vertical)
			}
			.edgesIgnoringSafeArea(.horizontal)
		}
		.focusSection()
	}
}
