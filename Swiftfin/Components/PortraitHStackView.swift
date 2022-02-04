//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct PortraitImageHStackView<TopBarView: View, ItemType: PortraitImageStackable>: View {

	let items: [ItemType]
	let maxWidth: CGFloat
	let horizontalAlignment: HorizontalAlignment
	let textAlignment: TextAlignment
	let topBarView: () -> TopBarView
	let selectedAction: (ItemType) -> Void

	init(items: [ItemType],
	     maxWidth: CGFloat = 110,
	     horizontalAlignment: HorizontalAlignment = .leading,
	     textAlignment: TextAlignment = .leading,
	     topBarView: @escaping () -> TopBarView,
	     selectedAction: @escaping (ItemType) -> Void)
	{
		self.items = items
		self.maxWidth = maxWidth
		self.horizontalAlignment = horizontalAlignment
		self.textAlignment = textAlignment
		self.topBarView = topBarView
		self.selectedAction = selectedAction
	}

	var body: some View {
		VStack(alignment: .leading, spacing: 0) {
			topBarView()

			ScrollView(.horizontal, showsIndicators: false) {
				HStack(alignment: .top, spacing: 15) {
					ForEach(items, id: \.self.portraitImageID) { item in
                        PortraitItemButton(item: item,
                                           maxWidth: maxWidth) { item in
                            selectedAction(item)
                        }
					}
				}
				.padding(.horizontal)
			}
		}
	}
}
