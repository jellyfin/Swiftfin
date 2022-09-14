//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension HomeView {

    struct CinematicRecentlyAddedView: View {

        @EnvironmentObject
        private var router: HomeCoordinator.Router
        @ObservedObject
        var viewModel: ItemTypeLibraryViewModel

        private func itemSelectorImageSource(for item: BaseItemDto) -> ImageSource {
            if item.type == .episode {
                return item.seriesImageSource(
                    .logo,
                    maxWidth: UIScreen.main.bounds.width * 0.4,
                    maxHeight: 200
                )
            } else {
                return item.imageSource(
                    .logo,
                    maxWidth: UIScreen.main.bounds.width * 0.4,
                    maxHeight: 200
                )
            }
        }

        var body: some View {
            CinematicItemSelector(items: viewModel.items.prefix(20).asArray)
                .topContent { item in
                    ImageView(itemSelectorImageSource(for: item))
                        .resizingMode(.bottomLeft)
                        .placeholder {
                            EmptyView()
                        }
                        .failure {
                            Text(item.displayName)
                                .font(.largeTitle)
                                .fontWeight(.semibold)
                        }
                        .padding2(.leading)
                }
                .onSelect { item in
                    router.route(to: \.item, item)
                }
                .trailingContent {
                    SeeAllPoster(type: .landscape)
                        .onSelect {
                            router.route(to: \.basicLibrary, .init(title: L10n.recentlyAdded, viewModel: viewModel))
                        }
                }
        }
    }
}
