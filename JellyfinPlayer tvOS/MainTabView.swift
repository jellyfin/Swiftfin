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

struct MainTabView: View {
    @State private var tabSelection: Tab = .home
    @StateObject private var viewModel = MainTabViewModel()
    @State private var backdropAnim: Bool = true
    @State private var lastBackdropAnim: Bool = false
    @FocusState private var tabViewIsFocused: Bool

    var body: some View {
        ZStack {
            // please do not touch my magical crossfading. i will wave my magical github wand and cry
            if let lastBackgroundURL = viewModel.lastBackgroundURL {
                ImageView(src: lastBackgroundURL, bh: viewModel.backgroundBlurHash)
                    .frame(minWidth: 100, maxWidth: .infinity, minHeight: 100, maxHeight: .infinity)
                    .opacity(lastBackdropAnim ? 0.4 : 0)
                    .ignoresSafeArea()
            }
            if let backgroundURL = viewModel.backgroundURL {
                ImageView(src: backgroundURL, bh: viewModel.backgroundBlurHash)
                    .frame(minWidth: 100, maxWidth: .infinity, minHeight: 100, maxHeight: .infinity)
                    .opacity(backdropAnim ? 0.4 : 0)
                    .onChange(of: viewModel.backgroundURL) { _ in
                        lastBackdropAnim = true
                        backdropAnim = false
                        withAnimation(.linear(duration: 0.33)) {
                            lastBackdropAnim = false
                            backdropAnim = true
                        }
                    }
                    .ignoresSafeArea()
            }

          
            if viewModel.isLoading {
                ProgressView()
            } else {
                TabView(selection: $tabSelection) {
                    HomeView()
                        .offset(y: -1) // don't remove this. it breaks tabview on 4K displays.
                    .tabItem {
                        Text("Home")
                        Image(systemName: "house")
                    }
                    .tag(Tab.home)
                    
                    ForEach(viewModel.libraries, id: \.id) { library in
                        if library.collectionType ?? "" == "movies" {
                            LibraryView(viewModel: .init(parentID: library.id), title: library.name ?? "")
                            .tabItem {
                                Text("Movies")
                                Image(systemName: "folder")
                            }
                            .tag(Tab.movies)
                        } else if library.collectionType ?? "" == "tvshows" {
                            LibraryView(viewModel: .init(parentID: library.id), title: library.name ?? "")
                            .tabItem {
                                Text("TV Shows")
                                Image(systemName: "folder")
                            }
                            .tag(Tab.tv)
                        } else if library.collectionType ?? "" == "livetv" {
                            Text("Coming Soon")
                            .tabItem {
                                Text("Live TV")
                                Image(systemName: "folder")
                            }
                            .tag(Tab.livetv)
                        }else {
                            LibraryView(viewModel: .init(parentID: library.id), title: library.name ?? "")
                            .tabItem {
                                Text("\(library.name ?? "Unnamed")")
                                Image(systemName: "folder")
                            }
                            .tag(Tab.tv)
                        }
                    }

                    SettingsView(viewModel: SettingsViewModel())
                        .offset(y: -1) // don't remove this. it breaks tabview on 4K displays.
                    .tabItem {
                        Text("Settings")
                        Image(systemName: "gear")
                    }
                    .tag(Tab.settings)
                }
                .onExitCommand {
                    self.viewModel.backgroundURL = nil
                    self.tabViewIsFocused = true
                }
                .focused($tabViewIsFocused)
            }
        }
    }
}

extension MainTabView {
    enum Tab: String {
        case home
        case allMedia
        case movies
        case tv
        case livetv
        case settings
    }
}

// stream ancient dreams in a modern land by MARINA!
