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
    private var tabRouter: MainCoordinator.Router
    @EnvironmentObject
    private var router: MediaCoordinator.Router
    @ObservedObject
    var viewModel: MediaViewModel

    @Default(.Experimental.liveTVAlphaEnabled)
    var liveTVEnabled

    private var libraryItems: [LibraryItem] {
        [.init(library: .init(name: L10n.favorites, collectionType: "favorites"), viewModel: viewModel)]
            .appending(.init(library: .init(name: "LiveTV", collectionType: "liveTV"), viewModel: viewModel), if: liveTVEnabled)
            .appending(viewModel.libraries)
    }

    var body: some View {
        CollectionView(items: libraryItems) { _, item, _ in
            PosterButton(item: item, type: .landscape)
                .scaleItem(0.8)
                .onSelect { _ in
                    switch item.library.collectionType {
                    case "favorites":
                        router.route(to: \.library, (viewModel: .init(filters: .favorites), title: ""))
                    case "liveTV":
                        tabRouter.root(\.liveTV)
                    default:
                        router.route(to: \.library, (viewModel: .init(library: item.library), title: ""))
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
                layoutMode: .adaptive(withMinItemSize: 400),
                lineSpacing: 50,
                itemSize: .estimated(400),
                sectionInsets: .zero
            )
        }
        .ignoresSafeArea()
    }
}
