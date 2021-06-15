/* JellyfinPlayer/Swiftfin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import SwiftUI
import Combine
import JellyfinAPI

struct NextUpView: View {

    var items: [BaseItemDto]

    var body: some View {
        VStack(alignment: .leading) {
            if items.count != 0 {
                Text("Next Up")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack {
                        Spacer().frame(width: 16)
                        ForEach(items, id: \.id) { item in
                            NavigationLink(destination: ItemView(item: item)) {
                                VStack(alignment: .leading) {
                                    ImageView(src: item.getSeriesPrimaryImage(baseURL: ServerEnvironment.current.server.baseURI!, maxWidth: 100), bh: item.getSeriesPrimaryImageBlurHash())
                                        .frame(width: 100, height: 150)
                                        .cornerRadius(10)
                                    Spacer().frame(height: 5)
                                    Text(item.seriesName!)
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                        .lineLimit(1)
                                    Text("S\(item.parentIndexNumber ?? 0):E\(item.indexNumber ?? 0)")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }.frame(width: 100)
                                Spacer().frame(width: 16)
                            }
                        }
                    }
                }
                .frame(height: 200)
            }
        }
        .padding(EdgeInsets(top: 4, leading: 0, bottom: 0, trailing: 0))
    }
}
