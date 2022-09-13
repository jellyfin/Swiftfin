//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI
import SwiftUICollection

struct MoviesLibraryView: View {
    
    @ObservedObject
    var viewModel: MoviesLibraryViewModel
    
    @ViewBuilder
    private var loadingView: some View {
        ProgressView()
    }

    @ViewBuilder
    private var noResultsView: some View {
        L10n.noResults.text
    }
    
    @ViewBuilder
    private var libraryItemsView: some View {
        PagingLibraryView(viewModel: viewModel)
            .ignoresSafeArea()
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.items.isEmpty {
                loadingView
            } else if viewModel.items.isEmpty {
                noResultsView
            } else {
                libraryItemsView
            }
        }
    }
}
