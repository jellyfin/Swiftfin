/*
 * JellyfinPlayer/Swiftfin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import SwiftUI

struct LibraryView: View {
    @StateObject var viewModel: LibraryViewModel
    var title: String

    // MARK: tracks for grid
    var defaultFilters = LibraryFilters(filters: [], sortOrder: [.ascending], withGenres: [], tags: [], sortBy: [.name])

    @State var isShowingSearchView = false
    @State var isShowingFilterView = false

    @State private var tracks: [GridItem] = Array(repeating: .init(.flexible()), count: Int(UIScreen.main.bounds.size.width) / 250)

    var body: some View {
        Group {
            if viewModel.isLoading == true {
                ProgressView()
            } else if !viewModel.items.isEmpty {
                ScrollView(.vertical) {
                    LazyVGrid(columns: tracks) {
                        ForEach(viewModel.items, id: \.id) { item in
                            if item.type != "Folder" {
                                NavigationLink(destination: LazyView { ItemView(item: item) }) {
                                    PortraitItemElement(item: item)
                                }.buttonStyle(PlainNavigationLinkButtonStyle())
                                    .onAppear {
                                        if item == viewModel.items.last && viewModel.hasNextPage {
                                            print("Last item visible, load more items.")
                                            viewModel.requestNextPageAsync()
                                        }
                                    }
                            }
                        }
                    }.padding()
                }
            } else {
                Text("No results.")
            }
        }
        /*
        .sheet(isPresented: $isShowingFilterView) {
            LibraryFilterView(filters: $viewModel.filters, enabledFilterType: viewModel.enabledFilterType, parentId: viewModel.parentID ?? "")
        }
        .background(
            NavigationLink(destination: LibrarySearchView(viewModel: .init(parentID: viewModel.parentID)),
                           isActive: $isShowingSearchView) {
                EmptyView()
            }
        )
        */
    }
}

// stream BM^S by nicki!
//
