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
import Stinsen
import SwiftUI

struct MediaView: View {

    @EnvironmentObject
    private var router: MediaCoordinator.Router
    @ObservedObject
    var viewModel: MediaViewModel
    @Default(.Experimental.liveTVAlphaEnabled)
    var liveTVEnabled

    private var libraryItems: [LibraryItem] {
        [LibraryItem(library: .init(name: L10n.favorites, id: "favorites"), viewModel: viewModel)]
            .appending(.init(library: .init(name: "LiveTV", id: "liveTV"), viewModel: viewModel), if: liveTVEnabled)
            .appending(viewModel.libraries.map { LibraryItem(library: $0, viewModel: viewModel) })
    }

    private var gridLayout: NSCollectionLayoutSection.GridLayoutMode {
        if UIDevice.isPhone {
            return .fixedNumberOfColumns(2)
        } else {
            return .adaptive(withMinItemSize: PosterType.landscape.width)
        }
    }

    var body: some View {
        CollectionView(items: libraryItems) { _, item, _ in
            PosterButton(item: item, type: .landscape)
                .scaleItem(UIDevice.isPhone ? 0.9 : 1)
                .onSelect { _ in
                    if item.library.id == "favorites" {
                        router.route(to: \.library, (viewModel: .init(filters: .favorites), title: ""))
                    } else if item.library.id == "liveTV" {
                        router.route(to: \.liveTV)
                    } else {
                        router.route(to: \.library, (viewModel: .init(parentID: item.library.id), title: ""))
                    }
                }
                .imageOverlay { _ in
                    ZStack {
                        Color.black
                            .opacity(0.5)

                        Text(item.library.displayName)
                            .foregroundColor(.white)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .frame(alignment: .center)
                    }
                }
        }
        .layout { _, layoutEnvironment in
            .grid(
                layoutEnvironment: layoutEnvironment,
                layoutMode: gridLayout,
                sectionInsets: .init(top: 0, leading: 10, bottom: 0, trailing: 10)
            )
        }
        .configure { configuration in
            configuration.showsVerticalScrollIndicator = false
        }
        .ignoresSafeArea()
        .navigationTitle(L10n.allMedia)
    }
}
