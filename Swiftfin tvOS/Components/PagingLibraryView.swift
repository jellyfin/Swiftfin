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
    private var libraryPosterType

    @ObservedObject
    private var viewModel: PagingLibraryViewModel
    
    private var onSelect: (BaseItemDto) -> Void
    
    private func layout(layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        switch libraryPosterType {
        case .portrait:
            return .grid(
                layoutEnvironment: layoutEnvironment,
                layoutMode: .fixedNumberOfColumns(7),
                lineSpacing: 50
            )
        case .landscape:
            return .grid(
                        layoutEnvironment: layoutEnvironment,
                        layoutMode: .adaptive(withMinItemSize: 400),
                        lineSpacing: 50,
                        itemSize: .estimated(400),
                        sectionInsets: .zero
                    )
        }
    }

    var body: some View {
        CollectionView(items: viewModel.items.elements) { _, item, _ in
            PosterButton(item: item, type: libraryPosterType)
                .onSelect {
                    onSelect(item)
                }
        }
        .layout { _, layoutEnvironment in
            layout(layoutEnvironment: layoutEnvironment)
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
        self.init(
            viewModel: viewModel, onSelect: { _ in }
        )
    }

    func onSelect(_ action: @escaping (BaseItemDto) -> Void) -> Self {
        copy(modifying: \.onSelect, with: action)
    }
}
