//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct ItemViewDetailsView: View {

	@ObservedObject
	var viewModel: ItemViewModel

	var body: some View {
		VStack(alignment: .leading) {

			if !viewModel.informationItems.isEmpty {
				VStack(alignment: .leading, spacing: 20) {
					L10n.information.text
						.font(.title3)
						.fontWeight(.bold)
						.accessibility(addTraits: [.isHeader])

					ForEach(viewModel.informationItems, id: \.self.title) { informationItem in
						VStack(alignment: .leading, spacing: 2) {
							Text(informationItem.title)
								.font(.subheadline)
							Text(informationItem.content)
								.font(.subheadline)
								.foregroundColor(Color.secondary)
						}
						.accessibilityElement(children: .combine)
					}
				}
				.padding(.bottom, 20)
			}

			VStack(alignment: .leading, spacing: 20) {
				L10n.media.text
					.font(.title3)
					.fontWeight(.bold)
					.accessibility(addTraits: [.isHeader])

				VStack(alignment: .leading, spacing: 2) {
					L10n.file.text
						.font(.subheadline)
					Text(viewModel.selectedVideoPlayerViewModel?.filename ?? "--")
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
						.font(.subheadline)
						.foregroundColor(Color.secondary)
				}
				.accessibilityElement(children: .combine)

				VStack(alignment: .leading, spacing: 2) {
					L10n.containers.text
						.font(.subheadline)
					Text(viewModel.selectedVideoPlayerViewModel?.container ?? "--")
						.font(.subheadline)
						.foregroundColor(Color.secondary)
				}
				.accessibilityElement(children: .combine)

				ForEach(viewModel.selectedVideoPlayerViewModel?.mediaItems ?? [], id: \.self.title) { mediaItem in
					VStack(alignment: .leading, spacing: 2) {
						Text(mediaItem.title)
							.font(.subheadline)
						Text(mediaItem.content)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
							.font(.subheadline)
							.foregroundColor(Color.secondary)
					}
					.accessibilityElement(children: .combine)
				}
			}
		}
	}
}
