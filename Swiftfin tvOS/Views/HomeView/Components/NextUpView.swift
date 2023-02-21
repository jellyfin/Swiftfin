//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension HomeView {

    struct NextUpView: View {

        @EnvironmentObject
        private var router: HomeCoordinator.Router
        @ObservedObject
        var viewModel: NextUpLibraryViewModel

        @Default(.Customization.nextUpPosterType)
        private var nextUpPosterType

        var body: some View {
            PosterHStack(
                title: L10n.nextUp,
                type: nextUpPosterType,
                items: viewModel.items.prefix(20).asArray
            )
            .trailing {
                Button {
                    router.route(to: \.basicLibrary, .init(title: L10n.nextUp, viewModel: viewModel))
                } label: {
                    HStack {
                        L10n.seeAll.text
                        Image(systemName: "chevron.right")
                    }
                    .font(.subheadline.bold())
                }
            }
            .onSelect { item in
                router.route(to: \.item, item)
            }
            .trailing {
                SeeAllPosterButton(type: nextUpPosterType)
                    .onSelect {
                        router.route(to: \.basicLibrary, .init(title: L10n.nextUp, viewModel: viewModel))
                    }
            }
        }
    }
}
