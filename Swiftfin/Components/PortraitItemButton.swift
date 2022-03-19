//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct PortraitItemButton<ItemType: PortraitImageStackable>: View {

	let item: ItemType
	let maxWidth: CGFloat
	let horizontalAlignment: HorizontalAlignment
	let textAlignment: TextAlignment
	let selectedAction: (ItemType) -> Void

	init(item: ItemType,
	     maxWidth: CGFloat = 110,
	     horizontalAlignment: HorizontalAlignment = .leading,
	     textAlignment: TextAlignment = .leading,
	     selectedAction: @escaping (ItemType) -> Void)
	{
		self.item = item
		self.maxWidth = maxWidth
		self.horizontalAlignment = horizontalAlignment
		self.textAlignment = textAlignment
		self.selectedAction = selectedAction
	}

	var body: some View {
		Button {
			selectedAction(item)
		} label: {
			VStack(alignment: horizontalAlignment) {
				ImageView(item.imageURLConstructor(maxWidth: Int(maxWidth)),
				          blurHash: item.blurHash,
                          failureView: {
                    InitialFailureView(item.failureInitials)
                })
					.portraitPoster(width: maxWidth)
					.shadow(radius: 4, y: 2)
					.accessibilityIgnoresInvertColors()

				if item.showTitle {
					Text(item.title)
						.font(.footnote)
						.fontWeight(.regular)
						.foregroundColor(.primary)
						.multilineTextAlignment(textAlignment)
						.fixedSize(horizontal: false, vertical: true)
						.lineLimit(2)
				}

				if let description = item.subtitle {
					Text(description)
						.font(.caption)
						.fontWeight(.medium)
						.foregroundColor(.secondary)
						.multilineTextAlignment(textAlignment)
						.fixedSize(horizontal: false, vertical: true)
						.lineLimit(2)
				}
			}
			.frame(width: maxWidth)
		}
		.frame(alignment: .top)
		.padding(.bottom)
	}
}
