/* JellyfinPlayer/Swiftfin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import Foundation
import SwiftUI

struct LibraryListView: View {
    @StateObject var viewModel = LibraryListViewModel()

    var body: some View {
        ScrollView {
            LazyVStack() {
                NavigationLink(destination: LazyView {
                    LibraryView(viewModel: .init(filters: viewModel.withFavorites), title: "Favorites")
                }) {
                    ZStack() {
                        HStack() {
                            Spacer()
                            Text("Your Favorites")
                                .foregroundColor(.black)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .padding(16)
                    .background(Color.white)
                    .frame(minWidth: 100, maxWidth: .infinity)
                }
                .cornerRadius(10)
                .shadow(radius: 5)
                .padding(.bottom, 5)
                
                NavigationLink(destination: LazyView {
                    Text("WIP")
                }) {
                    ZStack() {
                        HStack() {
                            Spacer()
                            Text("All Genres")
                                .foregroundColor(.black)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .padding(16)
                    .background(Color.white)
                    .frame(minWidth: 100, maxWidth: .infinity)
                }
                .cornerRadius(10)
                .shadow(radius: 5)
                .padding(.bottom, 15)
                
                ForEach(viewModel.libraries, id: \.id) { library in
                    NavigationLink(destination: LazyView {
                        LibraryView(viewModel: .init(parentID: library.id), title: library.name ?? "")
                    }) {
                        ZStack() {
                            ImageView(src: library.getPrimaryImage(maxWidth: 500))
                                .opacity(0.4)
                            HStack() {
                                Spacer()
                                Text(library.name ?? "")
                                    .foregroundColor(.white)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                Spacer()
                            }.padding(32)
                        }.background(Color.black)
                        .frame(minWidth: 100, maxWidth: .infinity)
                    }
                    .cornerRadius(10)
                    .shadow(radius: 5)
                    .padding(.bottom, 5)
                }
            }.padding(.leading, 16)
            .padding(.trailing, 16)
        }
        .navigationTitle("All Media")
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                NavigationLink(destination: LazyView {
                    LibrarySearchView(viewModel: .init(parentID: nil))
                }) {
                    Image(systemName: "magnifyingglass")
                }
            }
        }
    }
}
