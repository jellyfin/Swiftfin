/* JellyfinPlayer/Swiftfin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import Combine
import JellyfinAPI
import SwiftUI

struct LibrarySearchView: View {
    @StateObject var viewModel: LibrarySearchViewModel
    @State var searchQuery = ""

    @State private var tracks: [GridItem] = Array(repeating: .init(.flexible()), count: Int(UIScreen.main.bounds.size.width) / 125)

    func recalcTracks() {
        tracks = Array(repeating: .init(.flexible()), count: Int(UIScreen.main.bounds.size.width) / 125)
    }

    var body: some View {
        VStack {
            Spacer().frame(height: 6)
            SearchBar(text: $searchQuery)
            ZStack {
                if(!viewModel.isLoading) {
                    ScrollView(.vertical) {
                        if !viewModel.items.isEmpty {
                            Spacer().frame(height: 16)
                            LazyVGrid(columns: tracks) {
                                ForEach(viewModel.items, id: \.id) { item in
                                    NavigationLink(destination: ItemView(item: item)) {
                                        VStack(alignment: .leading) {
                                            ImageView(src: item.getPrimaryImage(maxWidth: 100), bh: item.getPrimaryImageBlurHash())
                                                .frame(width: 100, height: 150)
                                                .cornerRadius(10)
                                                .overlay(
                                                    ZStack {
                                                        if(item.userData!.played ?? false) {
                                                            Image(systemName: "circle.fill")
                                                                .foregroundColor(.white)
                                                            Image(systemName: "checkmark.circle.fill")
                                                                .foregroundColor(Color(.systemBlue))
                                                        }
                                                    }.padding(2)
                                                    .opacity(1)
                                                    , alignment: .topTrailing).opacity(1)
                                            Text(item.name ?? "")
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.primary)
                                                .lineLimit(1)
                                            if item.productionYear != nil {
                                                Text(String(item.productionYear!))
                                                    .foregroundColor(.secondary)
                                                    .font(.caption)
                                                    .fontWeight(.medium)
                                            } else {
                                                Text(item.type ?? "")
                                            }
                                        }.frame(width: 100)
                                    }
                                }
                                Spacer().frame(height: 16)
                            }
                            .onRotate { _ in
                                recalcTracks()
                            }
                        } else {
                            Text("Query returned 0 results.")
                        }
                    }
                } else {
                    ProgressView()
                }
            }
        }
        .onChange(of: searchQuery) { query in
            viewModel.searchQuerySubject.send(query)
        }
        .navigationBarTitle("Search", displayMode: .inline)
    }
}
