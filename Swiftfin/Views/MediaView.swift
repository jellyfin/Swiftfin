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
import Stinsen
import SwiftUI

struct MediaView: View {

    @EnvironmentObject
    private var router: MediaCoordinator.Router

    @ObservedObject
    var viewModel: MediaViewModel

    var body: some View {
        CollectionView(items: viewModel.libraryItems) { _, viewModel, _ in
            LibraryCard(viewModel: viewModel)
                .onSelect {
                    switch viewModel.item.collectionType {
                    case "downloads":
                        router.route(to: \.downloads)
                    case "favorites":
                        router.route(to: \.library, .init(parent: viewModel.item, type: .library, filters: .favorites))
                    case "folders":
                        router.route(to: \.library, .init(parent: viewModel.item, type: .folders, filters: .init()))
                    case "liveTV":
                        router.route(to: \.liveTV)
                    default:
                        router.route(to: \.library, .init(parent: viewModel.item, type: .library, filters: .init()))
                    }
                }
        }
        .layout { _, layoutEnvironment in
            let perRow: CGFloat = 2
            
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1 / perRow),
                heightDimension: .estimated(50)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(50)
            )
            
            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: groupSize,
                subitems: [item]
            )
            group.contentInsets = .init(top: 0, leading: 5, bottom: 0, trailing: 5)
            group.interItemSpacing = NSCollectionLayoutSpacing.fixed(10)

            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = 5
            
            return section
        }
        .configure { configuration in
            configuration.showsVerticalScrollIndicator = false
        }
        .ignoresSafeArea()
        .navigationTitle(L10n.allMedia)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if viewModel.isLoading {
                    ProgressView()
                }
            }
        }
    }
}

extension MediaView {

    struct LibraryCard: View {

        @ObservedObject
        var viewModel: MediaItemViewModel

        private var onSelect: () -> Void

        var body: some View {
            Button {
                onSelect()
            } label: {
//                ImageView(viewModel.imageSources ?? [])
                Color.blue
                    .overlay {
                        if Defaults[.Customization.Library.randomImage] ||
                            viewModel.item.collectionType == "favorites" ||
                            viewModel.item.collectionType == "downloads"
                        {
                            ZStack {
                                Color.black
                                    .opacity(0.5)

                                Text(viewModel.item.displayTitle)
                                    .foregroundColor(.white)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.center)
                                    .frame(alignment: .center)
                            }
                        }
                    }
                    .posterStyle(.landscape)
//                .frame(width: itemWidth)
            }
        }
    }
}

extension MediaView.LibraryCard {

    init(viewModel: MediaItemViewModel) {
        self.init(
            viewModel: viewModel,
            onSelect: {}
        )
    }

    func onSelect(_ action: @escaping () -> Void) -> Self {
        copy(modifying: \.onSelect, with: action)
    }
}
