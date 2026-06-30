//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension ItemView {

    struct ChannelItemContentView: View {

        @ObservedObject
        var viewModel: ChannelItemViewModel

        var body: some View {
            VStack(spacing: 0) {

                ProgramsRow(viewModel: viewModel.programs)

                ItemView.AboutView(viewModel: viewModel)
            }
        }
    }
}

private extension ItemView.ChannelItemContentView {

    struct ProgramsRow: View {

        @Router
        private var router

        @ObservedObject
        var viewModel: PagingLibraryViewModel<ChannelProgramsLibrary>

        var body: some View {
            if viewModel.elements.isNotEmpty {
                PosterHStack(
                    title: L10n.programs,
                    type: .landscape,
                    items: Array(viewModel.elements.prefix(25))
                ) { program in
                    router.route(to: .item(item: program))
                }
                .focusSection()
            }
        }
    }
}
