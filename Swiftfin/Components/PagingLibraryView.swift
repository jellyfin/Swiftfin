//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import CollectionView
import Defaults
import JellyfinAPI
import SwiftUI

struct PagingLibraryView: View {

    @Default(.Customization.Library.gridPosterType)
    private var libraryGridPosterType
    @Default(.Customization.Library.viewType)
    private var libraryViewType

    @ObservedObject
    var viewModel: PagingLibraryViewModel

    private var onSelect: (BaseItemDto) -> Void

    var body: some View {
        PagingCollectionView(
            items: $viewModel.items,
            viewType: $libraryViewType
        )
        .ignoresSafeArea()
    }
}

extension PagingLibraryView {
    
    init(viewModel: PagingLibraryViewModel) {
        self.init(
            viewModel: viewModel,
            onSelect: { _ in }
        )
    }

    func onSelect(_ action: @escaping (BaseItemDto) -> Void) -> Self {
        copy(modifying: \.onSelect, with: action)
    }
}
