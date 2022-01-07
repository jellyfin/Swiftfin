//
 /* 
  * SwiftFin is subject to the terms of the Mozilla Public
  * License, v2.0. If a copy of the MPL was not distributed with this
  * file, you can obtain one at https://mozilla.org/MPL/2.0/.
  *
  * Copyright 2021 Aiden Vigue & Jellyfin Contributors
  */

import Defaults
import Foundation
import SwiftUI

struct LibraryListView: View {
    @EnvironmentObject var mainCoordinator: MainCoordinator.Router
    @EnvironmentObject var libraryListRouter: LibraryListCoordinator.Router
    @StateObject var viewModel = LibraryListViewModel()
    
    @Default(.Experimental.liveTVAlphaEnabled) var liveTVAlphaEnabled

    var body: some View {
        ScrollView {
            LazyVStack {
                if !viewModel.isLoading {
                    
                    if let collectionLibraryItem = viewModel.libraries.first(where: { $0.collectionType == "boxsets" }) {
                        Button() {
                            self.libraryListRouter.route(to: \.library,
                                                         (viewModel: LibraryViewModel(parentID: collectionLibraryItem.id), title: collectionLibraryItem.name ?? ""))
                        }
                        label: {
                            ZStack {
                                HStack {
                                    Spacer()
                                    VStack {
                                        Text(collectionLibraryItem.name ?? "")
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
                    
                    ForEach(viewModel.libraries.filter({ $0.collectionType != "boxsets" }), id: \.id) { library in
                        if library.collectionType == "livetv" {
                            if liveTVAlphaEnabled {
                                Button() {
                                    self.mainCoordinator.root(\.liveTV)
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
                        } else {
                            Button() {
                                self.libraryListRouter.route(to: \.library, (viewModel: LibraryViewModel(), title: library.name ?? ""))
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
