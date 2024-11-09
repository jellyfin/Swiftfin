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

final class ItemDetailsCoordinator: ObservableObject, NavigationCoordinatable {

    let stack = NavigationStack(initial: \ItemDetailsCoordinator.start)

    @Root
    var start = makeStart

    @Route(.push)
    var editMetadata = makeEditMetadata
    @Route(.push)
    var editPeople = makeEditPeople
    @Route(.modal)
    var addPerson = makeAddPerson
    @Route(.push)
    var editStudios = makeEditStudios
    @Route(.modal)
    var addStudio = makeAddStudio
    @Route(.push)
    var editGenres = makeEditGenres
    @Route(.modal)
    var addGenre = makeAddGenre
    @Route(.push)
    var editTags = makeEditTags
    @Route(.modal)
    var addTag = makeAddTag

    private var item: BaseItemDto

    init(item: BaseItemDto) {
        self.item = item
    }

    @ViewBuilder
    func makeEditMetadata(viewModel: ItemDetailsViewModel) -> some View {
        EditMetadataView(viewModel: viewModel)
    }

    @ViewBuilder
    func makeEditPeople(viewModel: ItemDetailsViewModel) -> some View {
        EditPeopleView(viewModel: viewModel)
    }

    func makeAddPerson(viewModel: ItemDetailsViewModel) -> NavigationViewCoordinator<BasicNavigationViewCoordinator> {
        NavigationViewCoordinator {
            AddPeopleView(viewModel: viewModel)
        }
    }

    @ViewBuilder
    func makeEditStudios(viewModel: ItemDetailsViewModel) -> some View {
        EditStudioView(viewModel: viewModel)
    }

    func makeAddStudio(viewModel: ItemDetailsViewModel) -> NavigationViewCoordinator<BasicNavigationViewCoordinator> {
        NavigationViewCoordinator {
            AddStudioView(viewModel: viewModel)
        }
    }

    @ViewBuilder
    func makeEditGenres(viewModel: ItemDetailsViewModel) -> some View {
        EditGenreView(viewModel: viewModel)
    }

    func makeAddGenre(viewModel: ItemDetailsViewModel) -> NavigationViewCoordinator<BasicNavigationViewCoordinator> {
        NavigationViewCoordinator {
            AddGenreView(viewModel: viewModel)
        }
    }

    @ViewBuilder
    func makeEditTags(viewModel: ItemDetailsViewModel) -> some View {
        EditTagView(viewModel: viewModel)
    }

    func makeAddTag(viewModel: ItemDetailsViewModel) -> NavigationViewCoordinator<BasicNavigationViewCoordinator> {
        NavigationViewCoordinator {
            AddTagView(viewModel: viewModel)
        }
    }

    @ViewBuilder
    func makeStart() -> some View {
        ItemDetailsView(item: item)
    }
}
