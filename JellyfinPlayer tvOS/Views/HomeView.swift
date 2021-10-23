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
        ScrollView {
            if viewModel.isLoading {
                ProgressView()
            } else {
                LazyVStack(alignment: .leading) {
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

                                Button {
                                    self.homeRouter.route(to: \.modalLibrary, (.init(parentID: libraryID, filters: viewModel.recentFilterSet), title: library?.name ?? ""))
                                } label: {
                                    HStack {
                                        Text("Latest \(library?.name ?? "")")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        Image(systemName: "chevron.forward.circle.fill")
                                    }
                                }.padding(EdgeInsets(top: 0, leading: 90, bottom: 0, trailing: 0))
                                LatestMediaView(usingParentID: libraryID)
                            }
                        }
                    }
                    Spacer().frame(height: 30)
                }
            }
        }
    }
}
