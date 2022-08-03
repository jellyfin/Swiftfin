//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct LatestInLibraryView: View {

    @EnvironmentObject
    private var router: HomeCoordinator.Router
    @StateObject
    var viewModel: LatestMediaViewModel

    var body: some View {
        PortraitPosterHStack(
            title: L10n.latestWithString(viewModel.library.displayName),
            items: viewModel.items
        ) {
            Button {
                router.route(to: \.library, (
                    viewModel: .init(
                        parentID: viewModel.library.id!,
                        filters: LibraryFilters(
                            filters: [],
                            sortOrder: [.descending],
                            sortBy: [.dateAdded]
                        )
                    ),
                    title: viewModel.library.displayName
                ))
            } label: {
                ZStack {
                    Color(UIColor.darkGray)
                        .opacity(0.5)

                    VStack(spacing: 20) {
                        Image(systemName: "chevron.right")
                            .font(.title)

                        L10n.seeAll.text
                            .font(.title3)
                    }
                }
            }
            .frame(width: 257, height: 380)
            .buttonStyle(PlainButtonStyle())
        } selectedAction: { item in
            router.route(to: \.item, item)
        }
    }
}
