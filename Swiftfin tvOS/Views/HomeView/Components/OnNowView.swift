//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension HomeView {

    struct OnNowView: View {

        @Router
        private var router

        @ObservedObject
        var viewModel: PagingLibraryViewModel<RecommendedProgramsLibrary>

        var body: some View {
            if viewModel.elements.isNotEmpty {
                PosterHStack(
                    title: L10n.onNow,
                    type: .landscape,
                    items: viewModel.elements
                ) { item in
                    guard let userSession = viewModel.userSession else { return }
                    router.route(to: .videoPlayer(provider: item.getPlaybackItemProvider(userSession: userSession)))
                } label: { item in
                    ProgramButtonContent(program: item)
                }
                .posterOverlay(for: BaseItemDto.self) { item in
                    ProgramProgressOverlay(program: item)
                }
            }
        }
    }
}
