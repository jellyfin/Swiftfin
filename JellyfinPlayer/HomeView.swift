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
    @StateObject var viewModel = HomeViewModel()
    @Environment(\.horizontalSizeClass) var hSizeClass
    @Environment(\.verticalSizeClass) var vSizeClass
    @State var showingSettings = false
    
    @ViewBuilder
    var innerBody: some View {
        if(viewModel.isLoading) {
            ProgressView()
        } else {
            ScrollView {
                LazyVStack(alignment: .leading) {
                    if !viewModel.resumeItems.isEmpty {
                        ContinueWatchingView(items: viewModel.resumeItems)
                            .padding(.top, hSizeClass == .compact && vSizeClass == .regular ? 0 : 16)
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
                                        LibraryView(viewModel: .init(parentID: libraryID, filters: viewModel.recentFilterSet), title: library?.name ?? "")
                                    }) {
                                        HStack {
                                            Text("See All").font(.subheadline).fontWeight(.bold)
                                            Image(systemName: "chevron.right").font(Font.subheadline.bold())
                                        }
                                    }
                                }.padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                                LatestMediaView(viewModel: .init(libraryID: libraryID))
                            }.padding(EdgeInsets(top: 4, leading: 0, bottom: 0, trailing: 0))
                        }
                    }
                }
                .padding(.top, hSizeClass == .compact && vSizeClass == .regular ? 0 : 16)
                .padding(.bottom, UIDevice.current.userInterfaceIdiom == .phone ? 20 : 30)
            }
        }
    }
    
    var body: some View {
        innerBody
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
