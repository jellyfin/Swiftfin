/* JellyfinPlayer/Swiftfin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import Foundation
import SwiftUI

struct LibraryListView: View {
    @EnvironmentObject var globalData: GlobalData
    
    @State var library_ids: [String] = ["favorites", "genres"]
    @State var library_names: [String: String] = ["favorites": "Favorites", "genres": "Genres"]
    var libraries: [String: String] = [:] //input libraries
    var withFavorites: LibraryFilters = LibraryFilters(filters: [.isFavorite], sortOrder: [.descending], sortBy: ["SortName"])
    
    init(libraries: [String: String]) {
        self.libraries = libraries
    }
    
    func onAppear() {
        if(library_ids.count == 2) {
            libraries.forEach() { k,v in
                print("\(k): \(v)")
                _library_ids.wrappedValue.append(k)
                _library_names.wrappedValue[k] = v
            }
        }
    }
    
    var body: some View {
        List(library_ids, id: \.self) { key in
            switch key {
                case "favorites":
                    NavigationLink(destination: LazyView {
                        LibraryView(usingParentID: "", title: library_names[key] ?? "", usingFilters: withFavorites)
                    }) {
                        Text(library_names[key] ?? "")
                    }
                case "genres":
                    NavigationLink(destination: LazyView {
                        EmptyView()
                    }) {
                        Text(library_names[key] ?? "")
                    }
                default:
                    NavigationLink(destination: LazyView {
                        LibraryView(usingParentID: key, title: library_names[key] ?? "")
                    }) {
                        Text(library_names[key] ?? "")
                    }
            }
        }
        .navigationTitle("All Media")
        .onAppear(perform: onAppear)
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
