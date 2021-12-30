//
 /* 
  * SwiftFin is subject to the terms of the Mozilla Public
  * License, v2.0. If a copy of the MPL was not distributed with this
  * file, you can obtain one at https://mozilla.org/MPL/2.0/.
  *
  * Copyright 2021 Aiden Vigue & Jellyfin Contributors
  */

import Foundation
import SwiftUI

struct LibraryListView: View {
    @EnvironmentObject var mainCoordinator: MainCoordinator.Router
    @EnvironmentObject var libraryListRouter: LibraryListCoordinator.Router
    @StateObject var viewModel = LibraryListViewModel()

    var body: some View {
        ScrollView {
            LazyVStack {
                if !viewModel.isLoading {
                    ForEach(viewModel.libraries, id: \.id) { library in
                        if library.collectionType ?? "" == "movies" || library.collectionType ?? "" == "tvshows" || library.collectionType ?? "" == "music" {
                            EmptyView()
                        } else {
                            Button() {
                                if library.collectionType == "livetv" {
                                    self.mainCoordinator.root(\.liveTV)
                                } else {
                                    self.libraryListRouter.route(to: \.library, (viewModel: LibraryViewModel(), title: library.name ?? ""))
                                }
                            }
                            label: {
                                ZStack {
                                    HStack {
                                        Spacer()
                                        VStack {
                                            Text(library.name ?? "")
                                                .foregroundColor(.white)
                                                .font(.title2)
                                                .fontWeight(.semibold)
                                        }
                                        Spacer()
                                    }.padding(32)
                                }
                                .frame(minWidth: 100, maxWidth: .infinity)
                                .frame(height: 100)
                            }
                            .cornerRadius(10)
                            .shadow(radius: 5)
                            .padding(.bottom, 5)
                        }
                    }
                } else {
                    ProgressView()
                }
            }.padding(.leading, 16)
            .padding(.trailing, 16)
            .padding(.top, 8)
        }
    }
}
