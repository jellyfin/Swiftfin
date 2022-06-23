//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct PortraitImageHStack<ItemType: PortraitImageStackable, RightBarButton: View>: View {

    private let title: String
	private let items: [ItemType]
    private let itemWidth: CGFloat
    private let rightBarButton: () -> RightBarButton
    private let selectedAction: (ItemType) -> Void
    
    init(title: String,
         items: [ItemType],
         itemWidth: CGFloat = 110,
         @ViewBuilder rightBarButton: @escaping () -> RightBarButton,
         selectedAction: @escaping (ItemType) -> Void) {
        self.title = title
        self.items = items
        self.itemWidth = itemWidth
        self.rightBarButton = rightBarButton
        self.selectedAction = selectedAction
    }

	var body: some View {
		VStack(alignment: .leading) {
            HStack {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.leading)
                    .accessibility(addTraits: [.isHeader])
                
                Spacer()
                
                if let rightBarButton = rightBarButton {
                    rightBarButton()
                }
            }

			ScrollView(.horizontal, showsIndicators: false) {
				HStack(alignment: .top, spacing: 15) {
					ForEach(items, id: \.self.portraitImageID) { item in
                        PortraitItemButton(item: item,
                                           maxWidth: itemWidth,
                                           horizontalAlignment: .leading) { item in
                            selectedAction(item)
                        }
					}
				}
				.padding(.horizontal)
			}
		}
	}
}

extension PortraitImageHStack where RightBarButton == Spacer {
    init(title: String,
         items: [ItemType],
         itemWidth: CGFloat = 110,
         selectedAction: @escaping (ItemType) -> Void) {
        self.title = title
        self.items = items
        self.itemWidth = itemWidth
        self.rightBarButton = { Spacer() }
        self.selectedAction = selectedAction
    }
}
