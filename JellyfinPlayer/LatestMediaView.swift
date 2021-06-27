/* JellyfinPlayer/Swiftfin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import SwiftUI

struct LatestMediaView: View {
    @StateObject var viewModel: LatestMediaViewModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack {
                ForEach(viewModel.items, id: \.id) { item in
                    if item.type == "Series" || item.type == "Movie" {
                        PortraitItemView(item: item)
                    }
                }.padding(.trailing, 16)
            }.padding(.leading, 20)
        }.frame(height: 200)
    }
}
