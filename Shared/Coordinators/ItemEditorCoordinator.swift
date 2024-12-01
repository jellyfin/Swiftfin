//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import Stinsen
import SwiftUI

final class ItemEditorCoordinator: ObservableObject, NavigationCoordinatable {

    let stack = NavigationStack(initial: \ItemEditorCoordinator.start)

    @Root
    var start = makeStart

    private let viewModel: ItemViewModel

    // MARK: - Route to Metadata

    @Route(.modal)
    var editMetadata = makeEditMetadata

    // MARK: - Route to Genres

    @Route(.modal)
    var addGenre = makeAddGenre
    @Route(.push)
    var editGenres = makeEditGenres

    // MARK: - Route to Tags

    @Route(.modal)
    var addTag = makeAddTag
    @Route(.push)
    var editTags = makeEditTags

    // MARK: - Initializer

    init(viewModel: ItemViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Item Metadata

    func makeEditMetadata(item: BaseItemDto) -> NavigationViewCoordinator<BasicNavigationViewCoordinator> {
        NavigationViewCoordinator {
            EditMetadataView(viewModel: ItemEditorViewModel(item: item))
        }
    }

    // MARK: - Item Genres

    @ViewBuilder
    func makeEditGenres(item: BaseItemDto) -> some View {
        EditGenreView(viewModel: GenreEditorViewModel(item: item))
    }

    func makeAddGenre(viewModel: GenreEditorViewModel) -> NavigationViewCoordinator<BasicNavigationViewCoordinator> {
        NavigationViewCoordinator {
            AddGenreView(viewModel: viewModel)
        }
    }

    // MARK: - Item Tags

    @ViewBuilder
    func makeEditTags(item: BaseItemDto) -> some View {
        EditTagView(viewModel: TagEditorViewModel(item: item))
    }

    func makeAddTag(viewModel: TagEditorViewModel) -> NavigationViewCoordinator<BasicNavigationViewCoordinator> {
        NavigationViewCoordinator {
            AddTagView(viewModel: viewModel)
        }
    }

    // MARK: - Start

    @ViewBuilder
    func makeStart() -> some View {
        ItemEditorView(viewModel: viewModel)
    }
}
