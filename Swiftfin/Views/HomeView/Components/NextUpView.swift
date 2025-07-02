//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

extension HomeView {

    struct NextUpView: View {

        @Default(.Customization.nextUpPosterType)
        private var nextUpPosterType

        @Router
        private var router

        @ObservedObject
        var viewModel: NextUpLibraryViewModel

        private var onSetPlayed: (BaseItemDto) -> Void

        var body: some View {
            if viewModel.elements.isNotEmpty {
                PosterHStack(
                    title: L10n.nextUp,
                    type: nextUpPosterType,
                    items: viewModel.elements
                ) { item, namespace in
                    router.route(to: .item(item: item), in: namespace)
                } label: { item in
                    if item.type == .episode {
                        PosterButton.EpisodeContentSubtitleContent(item: item)
                    } else {
                        PosterButton.TitleSubtitleContentView(item: item)
                    }
                }
                .trailing {
                    SeeAllButton()
                        .onSelect {
                            router.route(to: .library(viewModel: viewModel))
                        }
                }
                .contextMenu(for: BaseItemDto.self) { item in
                    Button {
                        onSetPlayed(item)
                    } label: {
                        Label(L10n.played, systemImage: "checkmark.circle")
                    }
                }
            }
        }
    }
}

extension HomeView.NextUpView {

    init(viewModel: NextUpLibraryViewModel) {
        self.init(
            viewModel: viewModel,
            onSetPlayed: { _ in }
        )
    }

    func onSetPlayed(perform action: @escaping (BaseItemDto) -> Void) -> Self {
        copy(modifying: \.onSetPlayed, with: action)
    }
}
