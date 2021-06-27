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

    @State private var tracks: [GridItem] = Array(repeating: .init(.flexible()), count: Int(UIScreen.main.bounds.size.width) / 125)

    func recalcTracks() {
        tracks = Array(repeating: .init(.flexible()), count: Int(UIScreen.main.bounds.size.width) / 125)
    }

    var body: some View {
        Group {
            if viewModel.isLoading == true {
                ProgressView()
            } else if !viewModel.items.isEmpty {
                VStack {
                    ScrollView(.vertical) {
                        Spacer().frame(height: 16)
                        LazyVGrid(columns: tracks) {
                            ForEach(viewModel.items, id: \.id) { item in
                                if(item.type != "Folder") {
                                    PortraitItemView(item: item)
                                }
                            }
                        }.onRotate { _ in
                            recalcTracks()
                        }
                        if viewModel.hasNextPage || viewModel.hasPreviousPage {
                            HStack {
                                Spacer()
                                HStack {
                                    Button {
                                        viewModel.requestPreviousPage()
                                    } label: {
                                        Image(systemName: "chevron.left")
                                            .font(.system(size: 25))
                                    }.disabled(!viewModel.hasPreviousPage)
                                    Text("Page \(String(viewModel.currentPage + 1)) of \(String(viewModel.totalPages))")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Button {
                                        viewModel.requestNextPage()
                                    } label: {
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 25))
                                    }.disabled(!viewModel.hasNextPage)
                                }
                                Spacer()
                            }
                        }
                        Spacer().frame(height: 16)
                    }
                }
            } else {
                Text("No results.")
            }
        }
        .navigationBarTitle(title, displayMode: .inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if viewModel.hasPreviousPage {
                    Button {
                        viewModel.requestPreviousPage()
                    } label: {
                        Image(systemName: "chevron.left")
                    }.disabled(viewModel.isLoading)
                }
                if viewModel.hasNextPage {
                    Button {
                        viewModel.requestNextPage()
                    } label: {
                        Image(systemName: "chevron.right")
                    }.disabled(viewModel.isLoading)
                }
                Label("Icon One", systemImage: "line.horizontal.3.decrease.circle")
                .foregroundColor(viewModel.filters == defaultFilters ? .accentColor : Color(UIColor.systemOrange))
                .onTapGesture {
                    isShowingFilterView = true
                }
                Button {
                    isShowingSearchView = true
                } label: {
                    Image(systemName: "magnifyingglass")
                }
            }
        }
        .sheet(isPresented: $isShowingFilterView) {
            LibraryFilterView(filters: $viewModel.filters, enabledFilterType: viewModel.enabledFilterType, parentId: viewModel.parentID ?? "")
        }
        .background(
            NavigationLink(destination: LibrarySearchView(viewModel: .init(parentID: viewModel.parentID)),
                           isActive: $isShowingSearchView) {
                EmptyView()
            }
        )
    }
}

// stream BM^S by nicki!
//
