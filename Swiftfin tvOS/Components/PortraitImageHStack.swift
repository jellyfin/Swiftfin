//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI
import SwiftUICollection
import TVUIKit

// typealias LiveTVChannelRow = CollectionRow<Int, LiveTVChannelRowCell>

struct PortraitImageHStack<ItemType: PortraitImageStackable, LastView: View>: View {

	private let title: String
	private let items: [ItemType]
	private let selectedAction: (ItemType) -> Void
	private let lastView: () -> LastView

	init(title: String,
	     items: [ItemType],
	     @ViewBuilder lastView: @escaping () -> LastView,
	     selectedAction: @escaping (ItemType) -> Void)
	{
		self.title = title
		self.items = items
		self.lastView = lastView
		self.selectedAction = selectedAction
	}

	var body: some View {
		VStack(alignment: .leading) {

			Text(title)
				.font(.title3)
				.fontWeight(.semibold)
				.padding(.leading, 50)

			ScrollView(.horizontal) {
				HStack(alignment: .top, spacing: 0) {
					ForEach(items, id: \.portraitImageID) { item in
						PortraitButton(item: item) { item in
							selectedAction(item)
						}
					}

					lastView()
				}
				.padding(.horizontal, 50)
				.padding(.vertical)
				.padding(.vertical)
			}
			.edgesIgnoringSafeArea(.horizontal)
		}
	}
}

extension PortraitImageHStack where LastView == EmptyView {
	init(title: String,
	     items: [ItemType],
	     selectedAction: @escaping (ItemType) -> Void)
	{
		self.title = title
		self.items = items
		self.lastView = { EmptyView() }
		self.selectedAction = selectedAction
	}
}
