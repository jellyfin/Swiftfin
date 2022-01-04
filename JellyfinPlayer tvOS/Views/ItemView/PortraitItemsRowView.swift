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
                                itemRouter.route(to: \.item, item)
                            } label: {
                                ImageView(src: item.portraitHeaderViewURL(maxWidth: 200))
                                    .frame(width: 200, height: 334)
                            }
                            .frame(height: 334)
                            .buttonStyle(PlainButtonStyle())
                            
                            Text(item.title)
                                .lineLimit(2)
                                .frame(width: 200)
                        }
                    }
                }
                .padding(.horizontal, 50)
                .padding(.vertical)
            }
            .edgesIgnoringSafeArea(.horizontal)
        }
    }
}
