//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import BlurHashKit
import JellyfinAPI
import SwiftUI

extension CollectionItemView {

    struct ContentView: View {

        @EnvironmentObject
        private var router: ItemCoordinator.Router

        @ObservedObject
        var viewModel: CollectionItemViewModel

        var body: some View {
            VStack(alignment: .leading, spacing: 20) {

                VStack(alignment: .center) {
                    ImageView(viewModel.item.imageSource(.backdrop, maxWidth: 600))
                        .placeholder { source in
                            if let blurHash = source.blurHash {
                                BlurHashView(blurHash: blurHash, size: .Square(length: 8))
                            } else {
                                Color.secondarySystemFill
                                    .opacity(0.75)
                            }
                        }
                        .failure {
                            SystemImageContentView(systemName: viewModel.item.systemImage)
                        }
                        .posterStyle(.landscape, contentMode: .fill)
                        .frame(maxHeight: 300)
                        .posterShadow()
                        .edgePadding(.horizontal)

                    Text(viewModel.item.displayTitle)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.horizontal)

                    ItemView.ActionButtonHStack(viewModel: viewModel)
                        .font(.title)
                        .frame(maxWidth: 300)
                        .foregroundStyle(.primary)
                }

                // MARK: Overview

                ItemView.OverviewView(item: viewModel.item)
                    .overviewLineLimit(4)
                    .taglineLineLimit(2)
                    .padding(.horizontal)

                RowDivider()

                // MARK: Genres

                if let genres = viewModel.item.itemGenres, genres.isNotEmpty {
                    ItemView.GenresHStack(genres: genres)

                    RowDivider()
                }

                // MARK: Studios

                if let studios = viewModel.item.studios, studios.isNotEmpty {
                    ItemView.StudiosHStack(studios: studios)

                    RowDivider()
                }

                // MARK: Items

                if viewModel.collectionItems.isNotEmpty {
                    PosterHStack(
                        title: L10n.items,
                        type: .portrait,
                        items: viewModel.collectionItems
                    )
                    .trailing {
                        SeeAllButton()
                            .onSelect {
                                let viewModel = ItemLibraryViewModel(
                                    title: viewModel.item.displayTitle,
                                    id: viewModel.item.id,
                                    viewModel.collectionItems
                                )
                                router.route(to: \.library, viewModel)
                            }
                    }
                    .onSelect { item in
                        router.route(to: \.item, item)
                    }
                }
            }
        }
    }
}
