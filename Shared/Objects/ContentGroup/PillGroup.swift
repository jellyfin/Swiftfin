//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct PillGroup<Library: PagingLibrary>: _ContentGroup where Library.Element: Displayable {

    let displayTitle: String
    let id: String
    let library: Library
    let viewModel: PagingLibraryViewModel<Library>

    var _shouldBeResolved: Bool {
        viewModel.elements.isNotEmpty
    }

    init(
        displayTitle: String,
        id: String,
        library: Library
    ) {
        self.displayTitle = displayTitle
        self.id = id
        self.library = library
        self.viewModel = .init(library: library)
    }

    #if os(tvOS)
    func body(with viewModel: PagingLibraryViewModel<Library>) -> some View {
        EmptyView()
    }
    #else
    func body(with viewModel: PagingLibraryViewModel<Library>) -> some View {
        WithRouter { router in
            PillHStack(
                title: displayTitle,
                data: viewModel.elements
            ) { element in
                router.route(
                    to: .contentGroup(
                        provider: ItemTypeContentGroupProvider(
                            itemTypes: [
                                BaseItemKind.movie,
                                .series,
                                .boxSet,
                                .episode,
                                .musicVideo,
                                .video,
                                .liveTvProgram,
                                .tvChannel,
                                .musicArtist,
                                .person,
                            ],
                            parent: .init(id: "\(element.id)"),
                            environment: .init(
                                filters: .init(
                                    genres: [.init(
                                        stringLiteral: "\(element.id)"
                                    )]
                                )
                            )
                        )
                    )
                )
            }
        }
    }
    #endif
}
