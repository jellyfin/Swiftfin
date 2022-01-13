//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct ContinueWatchingView: View {

	@EnvironmentObject
	var homeRouter: HomeCoordinator.Router
	@ObservedObject
	var viewModel: HomeViewModel

	var body: some View {
		ScrollView(.horizontal, showsIndicators: false) {
			HStack(alignment: .top, spacing: 20) {
				ForEach(viewModel.resumeItems, id: \.id) { item in

					Button {
						homeRouter.route(to: \.item, item)
					} label: {
						VStack(alignment: .leading) {

							ZStack {
								ImageView(src: item.getBackdropImage(maxWidth: 320), bh: item.getBackdropImageBlurHash())
									.frame(width: 320, height: 180)

								HStack {
									VStack {

										Spacer()

										ZStack(alignment: .bottom) {

											LinearGradient(colors: [.clear, .black.opacity(0.5), .black.opacity(0.7)],
											               startPoint: .top,
											               endPoint: .bottom)
												.frame(height: 35)

											VStack(alignment: .leading, spacing: 0) {
												Text(item.getItemProgressString() ?? L10n.continue)
													.font(.subheadline)
													.padding(.bottom, 5)
													.padding(.leading, 10)
													.foregroundColor(.white)

												HStack {
													Color.jellyfinPurple
														.frame(width: 320 * (item.userData?.playedPercentage ?? 0) / 100, height: 7)

													Spacer(minLength: 0)
												}
											}
										}
									}
								}
							}
							.frame(width: 320, height: 180)
							.mask(Rectangle().cornerRadius(10))
							.shadow(radius: 4, y: 2)

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
					.contextMenu {
						Button(role: .destructive) {
							viewModel.removeItemFromResume(item)
						} label: {
							L10n.removeFromResume.text
						}
					}
				}
			}
			.padding(.horizontal)
		}
	}
}
