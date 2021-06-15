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

struct HomeView: View {
    @StateObject
    var viewModel = HomeViewModel()
    @State
    private var orientation = UIDevice.current.orientation
    @Environment(\.horizontalSizeClass)
    var hSizeClass
    @Environment(\.verticalSizeClass)
    var vSizeClass
    @State
    var showingSettings = false

    var body: some View {
        ZStack {
            ScrollView {
                LazyVStack(alignment: .leading) {
                    Spacer().frame(height: hSizeClass == .compact && vSizeClass == .regular ? 0 : 16)
                    if !viewModel.resumeItems.isEmpty {
                        ContinueWatchingView(items: viewModel.resumeItems)
                    }
                    if !viewModel.nextUpItems.isEmpty {
                        NextUpView(items: viewModel.nextUpItems)
                    }
                    if !viewModel.librariesShowRecentlyAddedIDs.isEmpty {
                        ForEach(viewModel.librariesShowRecentlyAddedIDs, id: \.self) { libraryID in
                            VStack(alignment: .leading) {
                                let library = viewModel.libraries.first(where: { $0.id == libraryID })
                                HStack {
                                    Text("Latest \(library?.name ?? "")")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 16))
                                    Spacer()
                                    NavigationLink(destination: LazyView {
                                        LibraryView(usingParentID: libraryID,
                                                    title: library?.name ?? "", usingFilters: viewModel.recentFilterSet)
                                    }) {
                                        HStack {
                                            Text("See All").font(.subheadline).fontWeight(.bold)
                                            Image(systemName: "chevron.right").font(Font.subheadline.bold())
                                        }
                                    }
                                }.padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                                LatestMediaView(usingParentID: libraryID)
                            }.padding(EdgeInsets(top: 4, leading: 0, bottom: 0, trailing: 0))
                        }
                    }

                    Spacer().frame(height: UIDevice.current.userInterfaceIdiom == .phone ? 20 : 30)
                }
            }
            if viewModel.isLoading {
                ProgressView()
            }
        }
        .onRotate {
            orientation = $0
        }
        .navigationTitle(MainTabView.Tab.home.localized)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gear")
                }
            }
        }
        .fullScreenCover(isPresented: $showingSettings) {
            SettingsView(viewModel: SettingsViewModel(), close: $showingSettings)
        }
    }
}
