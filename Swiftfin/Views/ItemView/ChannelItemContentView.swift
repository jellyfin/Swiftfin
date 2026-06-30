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
            SeparatorVStack(alignment: .leading) {
                RowDivider()
                    .padding(.vertical, 10)
            } content: {

                ProgramsRow(viewModel: viewModel.programs)

                if let genres = viewModel.item.itemGenres, genres.isNotEmpty {
                    ItemView.GenresHStack(genres: genres)
                }

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
                ) { program, namespace in
                    router.route(to: .item(item: program), in: namespace)
                }
                .trailing {
                    SeeAllButton {
                        router.route(to: .library(library: viewModel.library))
                    }
                }
            }
        }
    }
}
