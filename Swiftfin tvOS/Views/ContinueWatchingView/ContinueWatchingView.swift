/*
 * JellyfinPlayer/Swiftfin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import SwiftUI
import JellyfinAPI
import Combine
import Stinsen

struct ContinueWatchingView: View {
    
    @EnvironmentObject var homeRouter: HomeCoordinator.Router
    let items: [BaseItemDto]

    var body: some View {
        VStack(alignment: .leading) {
            
            L10n.continueWatching.text
                .font(.title3)
                .fontWeight(.semibold)
                .padding(.leading, 50)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .top) {
                    ForEach(items, id: \.self) { item in
                        ContinueWatchingCard(item: item)
                    }
                }
                .padding(.horizontal, 50)
            }
        }
    }
}
