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

    private var gridLayout: NSCollectionLayoutSection.GridLayoutMode {
        if libraryGridPosterType == .landscape && UIDevice.isPhone {
            return .fixedNumberOfColumns(2)
        } else {
            return .adaptive(withMinItemSize: 200 + (UIDevice.isIPad ? 10 : 0))
        }
    }

    @ViewBuilder
    private var libraryListView: some View {
        CollectionView(items: viewModel.items.elements) { _, item, _ in
            LibraryItemRow(item: item)
                .onSelect {
                    onSelect(item)
                }
                .padding()
        }
        .layout { _, layoutEnvironment in
            .list(using: .init(appearance: .plain), layoutEnvironment: layoutEnvironment)
        }
        .willReachEdge(insets: .init(top: 0, leading: 0, bottom: 200, trailing: 0)) { edge in
            if !viewModel.isLoading && edge == .bottom {
                viewModel.requestNextPage()
            }
        }
        .onEdgeReached { edge in
            if viewModel.hasNextPage, !viewModel.isLoading, edge == .bottom {
                viewModel.requestNextPage()
            }
        }
        .configure { configuration in
            configuration.showsVerticalScrollIndicator = false
        }
    }

    @ViewBuilder
    private var libraryGridView: some View {
        CollectionView(items: viewModel.items.elements) { _, item, _ in
            PosterButton(item: item, type: libraryGridPosterType)
                .scaleItem(libraryGridPosterType == .landscape && UIDevice.isPhone ? 0.85 : 1)
                .onSelect {
                    onSelect(item)
                }
        }
        .layout { _, layoutEnvironment in
            
//            layoutEnvironment.container.effectiveContentSize.width
            
            return .grid(
                layoutEnvironment: layoutEnvironment,
                layoutMode: .fixedNumberOfColumns(3),
                itemSpacing: 10,
                lineSpacing: 10,
                itemSize: .fractionalWidth(1/3),
                sectionInsets: .init(top: 10, leading: 10, bottom: 10, trailing: 10)
            )
        }
        .willReachEdge(insets: .init(top: 0, leading: 0, bottom: 200, trailing: 0)) { edge in
            if !viewModel.isLoading && edge == .bottom {
                viewModel.requestNextPage()
            }
        }
        .onEdgeReached { edge in
            if viewModel.hasNextPage, !viewModel.isLoading, edge == .bottom {
                viewModel.requestNextPage()
            }
        }
        .configure { configuration in
            configuration.showsVerticalScrollIndicator = false
        }
    }

    var body: some View {
        switch libraryViewType {
        case .grid:
            libraryGridView
        case .list:
            libraryListView
        }
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

class UILibraryCollectionView: UICollectionView {
    
    private func createPortraiGridLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .absolute(100),
                                             heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                               heightDimension: .fractionalHeight(0.3))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize,
                                                         subitems: [item])

        let section = NSCollectionLayoutSection(group: group)

        let layout = UICollectionViewCompositionalLayout(section: section)
        
//        let b = UICollectionViewCompositionalLayout(
//            sectionProvider: <#T##UICollectionViewCompositionalLayoutSectionProvider##UICollectionViewCompositionalLayoutSectionProvider##(Int, NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection?#>,
//            configuration: .init().
//        )
        
        return layout
    }
    
    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: .zero, collectionViewLayout: layout)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
