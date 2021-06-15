/* JellyfinPlayer/Swiftfin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import Foundation
import SwiftUI

struct LibraryListView: View {
    @StateObject
    var viewModel = LibraryListViewModel()

    var body: some View {
        List(viewModel.libraries, id: \.self) { library in
            switch library.id {
            case "favorites":
                NavigationLink(destination: LazyView {
                    LibraryView(usingParentID: "", title: library.name ?? "", usingFilters: viewModel.withFavorites)
                }) {
                    Text(library.name ?? "")
                }
            case "genres":
                NavigationLink(destination: LazyView {
                    EmptyView()
                }) {
                    Text(library.name ?? "")
                }
            default:
                NavigationLink(destination: LazyView {
                    LibraryView(usingParentID: library.id ?? "", title: library.name ?? "")
                }) {
                    Text(library.name ?? "")
                }
            }
        }
        .navigationTitle("All Media")
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                NavigationLink(destination: LazyView {
                    LibrarySearchView(usingParentID: "")
                }) {
                    Image(systemName: "magnifyingglass")
                }
            }
        }
    }
}
