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
//        PagingCollectionView(items: $viewModel.items, viewType: $libraryViewType) { item in
//            switch libraryViewType {
//            case .grid:
//                PosterButton(item: item, type: libraryGridPosterType)
//                    .onSelect {
//                        onSelect(item)
//                    }
//            case .list:
//                LibraryItemRow(item: item)
//                    .padding(.vertical, 5)
//            }
//        }
//        .ignoresSafeArea()
        
        CollectionVGrid(
            $viewModel.items,
            layout: $layout
        ) { item in
            switch libraryViewType {
            case .grid:
                PosterButton(item: item, type: libraryGridPosterType)
                    .onSelect {
                        onSelect(item)
                    }
            case .list:
                LibraryItemRow(item: item)
                    .padding(5)
            }
        }
        .ignoresSafeArea()
        .onChange(of: libraryViewType) { newValue in
            switch newValue {
            case .grid:
                layout = .minWidth(100)
            case .list:
                layout = .columns(1, insets: .init(constant: 0), itemSpacing: 0, lineSpacing: 0)
            }
        }
    }
}

extension PagingLibraryView {

    init(viewModel: PagingLibraryViewModel) {
        
        let layout: CollectionVGridLayout
        
        switch Defaults[.Customization.Library.viewType] {
        case .grid:
            layout = .minWidth(120)
        case .list:
            layout = .columns(1, insets: .init(constant: 0), itemSpacing: 0, lineSpacing: 0)
        }
        
        self.init(
            viewModel: viewModel,
            layout: layout,
            onSelect: { _ in }
        )
    }

    func onSelect(_ action: @escaping (BaseItemDto) -> Void) -> Self {
        copy(modifying: \.onSelect, with: action)
    }
}
