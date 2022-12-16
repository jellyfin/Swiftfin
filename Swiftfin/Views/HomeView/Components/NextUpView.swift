//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

extension HomeView {

    struct NextUpView: View {

        @Default(.Customization.nextUpPosterType)
        private var nextUpPosterType

        @EnvironmentObject
        private var router: HomeCoordinator.Router

        @ObservedObject
        var viewModel: NextUpLibraryViewModel

        private var items: [PosterButtonType<BaseItemDto>] {
//            if viewModel.isLoading {
//                return PosterButtonType.loading.random(in: 3 ..< 8)
//            } else {
            viewModel.items.prefix(20).asArray.map { .item($0) }
//            }
        }

        var body: some View {
            PosterHStack(
                title: L10n.nextUp,
                type: nextUpPosterType,
                items: items
            )
            .trailing {
                SeeAllButton()
                    .onSelect {
                        router.route(to: \.basicLibrary, .init(title: L10n.nextUp, viewModel: viewModel))
                    }
            }
            .contextMenu { state in
                if case let PosterButtonType.item(item) = state {
                    Button {
                        viewModel.markPlayed(item: item)
                    } label: {
                        Label("Played", systemImage: "checkmark.circle")
                    }
                }
            }
            .onSelect { item in
                router.route(to: \.item, item)
            }
        }
    }
}
