//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct CinematicNextUpCardView: View {

	@EnvironmentObject
	var homeRouter: HomeCoordinator.Router
	let item: BaseItemDto
	let showOverlay: Bool

	var body: some View {
		VStack(alignment: .leading) {
			Button {
				homeRouter.route(to: \.modalItem, item)
			} label: {
				ZStack(alignment: .bottomLeading) {

					if item.itemType == .episode {
						ImageView(sources: [
							item.getSeriesThumbImage(maxWidth: 350),
							item.getSeriesBackdropImage(maxWidth: 350),
						])
						.frame(width: 350, height: 210)
					} else {
						ImageView([
							.init(url: item.getThumbImage(maxWidth: 350)),
							.init(url: item.getBackdropImage(maxWidth: 350), blurHash: item.getBackdropImageBlurHash()),
						])
						.frame(width: 350, height: 210)
					}

					LinearGradient(colors: [.clear, .black],
					               startPoint: .top,
					               endPoint: .bottom)
						.frame(height: 105)
						.ignoresSafeArea()

					if showOverlay {
						VStack(alignment: .leading, spacing: 0) {
							L10n.next.text
								.font(.subheadline)
								.padding(.vertical, 5)
								.padding(.leading, 10)
								.foregroundColor(.white)

							HStack {
								Color.clear
									.frame(width: 1, height: 7)
							}
						}
					}
				}
				.frame(width: 350, height: 210)
			}
			.buttonStyle(CardButtonStyle())
			.padding(.top)
		}
		.padding(.vertical)
	}
}
