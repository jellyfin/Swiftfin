//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

extension ItemView.AboutView {

    struct ImageCard: View {

        // MARK: - Environment & Observed Objects

        @Router
        private var router

        @ObservedObject
        var viewModel: ItemViewModel

        // MARK: - Body

        var body: some View {
            PosterButton(
                item: viewModel.item,
                type: .portrait,
                action: onSelect
            ) {
                EmptyView()
            }
            .posterOverlay(for: BaseItemDto.self) { _ in EmptyView() }
            .frame(height: 405)
        }

        // MARK: - On Select

        // Switch case to allow other funcitonality if we need to expand this beyond episode > series
        private func onSelect() {
            switch viewModel.item.type {
            case .episode:
                if let episodeViewModel = viewModel as? EpisodeItemViewModel,
                   let seriesItem = episodeViewModel.seriesItem
                {
                    router.route(to: .item(item: seriesItem))
                }
            default:
                break
            }
        }
    }
}
