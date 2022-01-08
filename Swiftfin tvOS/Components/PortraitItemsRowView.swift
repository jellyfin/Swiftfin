//
 /* 
  * SwiftFin is subject to the terms of the Mozilla Public
  * License, v2.0. If a copy of the MPL was not distributed with this
  * file, you can obtain one at https://mozilla.org/MPL/2.0/.
  *
  * Copyright 2021 Aiden Vigue & Jellyfin Contributors
  */

import SwiftUI
import JellyfinAPI

struct PortraitItemsRowView: View {
    
    @EnvironmentObject var itemRouter: ItemCoordinator.Router
    
    let rowTitle: String
    let items: [BaseItemDto]
    let showItemTitles: Bool
    let selectedAction: (BaseItemDto) -> Void
    
    init(rowTitle: String,
         items: [BaseItemDto],
         showItemTitles: Bool = true,
         selectedAction: @escaping (BaseItemDto) -> Void) {
        self.rowTitle = rowTitle
        self.items = items
        self.showItemTitles = showItemTitles
        self.selectedAction = selectedAction
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            
            Text(rowTitle)
                .font(.title3)
                .padding(.horizontal, 50)
            
            ScrollView(.horizontal) {
                HStack(alignment: .top) {
                    ForEach(items, id: \.self) { item in
                        
                        VStack(spacing: 15) {
                            Button {
                                selectedAction(item)
                            } label: {
                                ImageView(src: item.portraitHeaderViewURL(maxWidth: 257))
                                    .frame(width: 257, height: 380)
                            }
                            .frame(height: 380)
                            .buttonStyle(PlainButtonStyle())
                            
                            if showItemTitles {
                                Text(item.title)
                                    .lineLimit(2)
                                    .frame(width: 257)
                            }
                        }
                    }
                }
                .padding(.horizontal, 50)
                .padding(.vertical)
            }
            .edgesIgnoringSafeArea(.horizontal)
        }
        .focusSection()
    }
}
