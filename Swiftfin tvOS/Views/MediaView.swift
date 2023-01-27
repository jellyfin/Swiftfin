//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import CollectionView
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

    var body: some View {
        CollectionView(items: viewModel.libraryItems) { _, item, _ in
            PosterButton(item: item, type: .landscape)
                .scaleItem(1.12)
                .onSelect {
                    switch item.library.collectionType {
                    case "favorites":
                        router.route(to: \.library, .init(parent: item.library, type: .library, filters: .favorites))
                    case "folders":
                        router.route(to: \.library, .init(parent: item.library, type: .folders, filters: .init()))
                    case "liveTV":
                        tabRouter.root(\.liveTV)
                    default:
                        router.route(to: \.library, .init(parent: item.library, type: .library, filters: .init()))
                    }
                }
                .imageOverlay {
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
