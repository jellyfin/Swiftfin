//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import CollectionView
import Defaults
import JellyfinAPI
import SwiftUI

struct PagingLibraryView: View {

    @ObservedObject
    var viewModel: PagingLibraryViewModel
    private var onSelect: (BaseItemDto) -> Void

    @Default(.Customization.Library.gridPosterType)
    private var libraryPosterType

    var body: some View {
        CollectionView(items: viewModel.items) { _, item, _ in
            PosterButton(item: item, type: libraryPosterType)
                .onSelect {
                    onSelect(item)
                }
        }
        .layout { _, layoutEnvironment in
            .grid(
                layoutEnvironment: layoutEnvironment,
                layoutMode: .fixedNumberOfColumns(7),
                lineSpacing: 50
            )
        }
        .willReachEdge(insets: .init(top: 0, leading: 0, bottom: 600, trailing: 0)) { edge in
            if !viewModel.isLoading && edge == .bottom {
                viewModel.requestNextPage()
            }
        }
    }
}

extension PagingLibraryView {
    init(viewModel: PagingLibraryViewModel) {
        self.viewModel = viewModel
        self.onSelect = { _ in }
    }

    func onSelect(_ action: @escaping (BaseItemDto) -> Void) -> Self {
        var copy = self
        copy.onSelect = action
        return copy
    }
}
