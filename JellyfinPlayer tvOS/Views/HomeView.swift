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
    @EnvironmentObject var homeRouter: HomeCoordinator.Router
    @StateObject var viewModel = HomeViewModel()

    @State var showingSettings = false

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(2)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading) {
                        if !viewModel.resumeItems.isEmpty {
                            ContinueWatchingView(items: viewModel.resumeItems)
                        }
                        
                        if !viewModel.nextUpItems.isEmpty {
                            NextUpView(items: viewModel.nextUpItems)
                        }

                        ForEach(viewModel.libraries, id: \.self) { library in
                            Button {
                                self.homeRouter.route(to: \.modalLibrary, (.init(parentID: library.id, filters: viewModel.recentFilterSet), title: library.name ?? ""))
                            } label: {
                                HStack {
                                    Text(L10n.latestWithString(library.name ?? ""))
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    Image(systemName: "chevron.forward.circle.fill")
                                }
                            }.padding(EdgeInsets(top: 0, leading: 90, bottom: 0, trailing: 0))
                            
                            LatestMediaView(usingParentID: library.id ?? "")
                        }
                        
                        Spacer(minLength: 100)
                        
                        HStack {
                            Spacer()
                            
                            Button {
                                viewModel.refresh()
                            } label: {
                                Text("Refresh")
                            }
                            
                            Spacer()
                        }
                        .focusSection()
                    }
                }
            }
        }
    }
}
