//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import CollectionVGrid
import CollectionView
import Defaults
import JellyfinAPI
import SwiftUI

// TODO: pad vs phone layouts
// TODO: find better way to init layout
// - is onAppear good enough since right now it will always open up in loading state?
// - that should change if/when better caching is implemented
// TODO: on pad: list layout columns (up to 3?)?

struct PagingLibraryView: View {

    @Default(.Customization.Library.gridPosterType)
    private var libraryGridPosterType
    @Default(.Customization.Library.viewType)
    private var libraryViewType

    @ObservedObject
    var viewModel: PagingLibraryViewModel
    
    @State
    private var layout: CollectionVGridLayout

    private var onSelect: (BaseItemDto) -> Void

    var body: some View {
        CollectionVGrid(
            $viewModel.items,
            layout: $layout
        ) { item in
            switch libraryViewType {
            case .grid:
                PosterButton(item: item, type: libraryGridPosterType)
                    .content { item in
                        if item.showTitle {
                            PosterButton.TitleContentView(item: item)
                                .reservingSpaceLineLimit(1)
                        }
                    }
                    .onSelect {
                        onSelect(item)
                    }
            case .list:
                LibraryItemRow(item: item)
                    .onSelect {
                        onSelect(item)
                    }
                    .padding(5)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            switch (libraryViewType, libraryGridPosterType) {
            case (.grid, .portrait):
                layout = .columns(3)
            case (.grid, .landscape):
                layout = .columns(2)
            case (.list, _):
                layout = .columns(1, insets: .init(constant: 0), itemSpacing: 0, lineSpacing: 0)
            }
        }
        .onChange(of: libraryViewType) { newValue in
            switch (newValue, libraryGridPosterType) {
            case (.grid, .portrait):
                layout = .columns(3)
            case (.grid, .landscape):
                layout = .columns(2)
            case (.list, _):
                layout = .columns(1, insets: .init(constant: 0), itemSpacing: 0, lineSpacing: 0)
            }
        }
    }
}

extension PagingLibraryView {

    init(viewModel: PagingLibraryViewModel) {
        self.init(
            viewModel: viewModel,
            layout: .columns(3),
            onSelect: { _ in }
        )
    }

    func onSelect(_ action: @escaping (BaseItemDto) -> Void) -> Self {
        copy(modifying: \.onSelect, with: action)
    }
}
