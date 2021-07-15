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
        ZStack {
            VStack {
                SearchBar(text: $searchQuery)
                    .padding(.vertical, 8)
                if searchQuery.isEmpty {
                    suggestionsListView
                } else {
                    itemsGridView
                }
            }
            if viewModel.isLoading {
                ProgressView()
            }
        }
        .onChange(of: searchQuery) { query in
            viewModel.searchQuerySubject.send(query)
        }
        .navigationBarTitle("Search", displayMode: .inline)
    }
    
    var suggestionsListView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 8) {
                Text("Suggestions")
                    .font(.title)
                    .foregroundColor(.primary)
                    .padding(.bottom, 8)
                ForEach(viewModel.suggestions, id: \.id) { item in
                    Button {
                        searchQuery = item.name ?? ""
                    } label: {
                        Text(item.name ?? "")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    var itemsGridView: some View {
        ScrollView {
            if !viewModel.items.isEmpty {
                LazyVGrid(columns: tracks) {
                    ForEach(viewModel.items, id: \.id) { item in
                        PortraitItemView(item: item)
                    }
                }
                .padding(.bottom, 16)
                .onRotate { _ in
                    recalcTracks()
                }
            } else {
                Text("Query returned 0 results.")
            }
        }
    }
}
