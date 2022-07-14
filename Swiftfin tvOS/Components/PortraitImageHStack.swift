//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct PortraitImageHStack<ItemType: PortraitImageStackable>: View {
    
    private let title: String
    private let items: [ItemType]
    private let selectedAction: (ItemType) -> Void

	init(title: String,
	     items: [ItemType],
	     selectedAction: @escaping (ItemType) -> Void)
	{
		self.title = title
		self.items = items
		self.selectedAction = selectedAction
	}

	var body: some View {
		VStack(alignment: .leading) {

			Text(title)
				.font(.title3)
                .fontWeight(.semibold)
				.padding(.leading, 50)

			ScrollView(.horizontal) {
				HStack(alignment: .top) {
                    ForEach(items, id: \.portraitImageID) { item in
                        PortraitButton(item: item) { item in
                            selectedAction(item)
                        }
					}
				}
				.padding(.horizontal, 50)
				.padding(.vertical)
                .padding(.top)
			}
			.edgesIgnoringSafeArea(.horizontal)
		}
		.focusSection()
	}
}
