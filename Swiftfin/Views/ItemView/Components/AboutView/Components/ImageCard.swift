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

extension ItemView.AboutView {

    struct ImageCard: View {

        @Namespace
        private var namespace

        @Router
        private var router

        private let item: BaseItemDto

        init(viewModel: ItemViewModel) {
            self.item = viewModel.item
        }

        init(item: BaseItemDto) {
            self.item = item
        }

        private func action() {
//            switch item.type {
//            case .episode:
//                if let episodeViewModel = viewModel as? EpisodeItemViewModel,
//                   let seriesItem = episodeViewModel.seriesItem
//                {
//                    router.route(to: .item(item: seriesItem), in: namespace)
//                }
//            default:
//                break
//            }
        }

        var body: some View {
            Button(action: action) {
                PosterImage(
                    item: item,
                    type: .portrait
                )
                .backport
                .matchedTransitionSource(id: "item", in: namespace)
                .posterShadow()
            }
        }
    }
}
