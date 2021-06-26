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
                        NavigationLink(destination: LazyView { ItemView(item: item) }) {
                            VStack(alignment: .leading) {
                                ImageView(src: item.getPrimaryImage(maxWidth: 100), bh: item.getPrimaryImageBlurHash())
                                    .frame(width: 100, height: 150)
                                    .cornerRadius(10)
                                    .shadow(radius: 4)
                                    .overlay(
                                        ZStack {
                                            if item.userData!.played ?? false {
                                                Image(systemName: "circle.fill")
                                                    .foregroundColor(.white)
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(Color(.systemBlue))
                                            }
                                        }.padding(2)
                                        .opacity(1), alignment: .topTrailing).opacity(1)
                                Text(item.seriesName ?? item.name ?? "")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                if item.productionYear != nil {
                                    Text(String(item.productionYear ?? 0))
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                } else {
                                    Text(item.type!)
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                            }.frame(width: 100)
                        }
                    }
                }.padding(.trailing, 16)
            }.padding(.leading, 20)
        }.frame(height: 195)
    }
}
