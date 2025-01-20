//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
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

    @Route(.push)
    var identifyItem = makeIdentifyItem
    @Route(.modal)
    var editMetadata = makeEditMetadata

    // MARK: - Route to Images

    @Route(.modal)
    var editImages = makeEditImages

    // MARK: - Route to Genres

    @Route(.push)
    var editGenres = makeEditGenres
    @Route(.modal)
    var addGenre = makeAddGenre

    // MARK: - Route to Tags

    @Route(.push)
    var editTags = makeEditTags
    @Route(.modal)
    var addTag = makeAddTag

    // MARK: - Route to Studios

    @Route(.push)
    var editStudios = makeEditStudios
    @Route(.modal)
    var addStudio = makeAddStudio

    // MARK: - Route to People

    @Route(.push)
    var editPeople = makeEditPeople
    @Route(.modal)
    var addPeople = makeAddPeople

    // MARK: - Initializer

    init(viewModel: ItemViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Item Metadata

    @ViewBuilder
    func makeIdentifyItem(item: BaseItemDto) -> some View {
        IdentifyItemView(item: item)
    }

    func makeEditMetadata(item: BaseItemDto) -> NavigationViewCoordinator<BasicNavigationViewCoordinator> {
        NavigationViewCoordinator {
            EditMetadataView(viewModel: ItemEditorViewModel(item: item))
        }
    }

    // MARK: - Item Images

    func makeEditImages(viewModel: ItemImagesViewModel) -> NavigationViewCoordinator<ItemImagesCoordinator> {
        NavigationViewCoordinator(ItemImagesCoordinator(viewModel: viewModel))
    }

    // MARK: - Item Genres

    @ViewBuilder
    func makeEditGenres(item: BaseItemDto) -> some View {
        EditItemElementView<String>(
            viewModel: GenreEditorViewModel(item: item),
            type: .genres,
            route: { router, viewModel in
                router.route(to: \.addGenre, viewModel as! GenreEditorViewModel)
            }
        )
    }

    func makeAddGenre(viewModel: GenreEditorViewModel) -> NavigationViewCoordinator<BasicNavigationViewCoordinator> {
        NavigationViewCoordinator {
            AddItemElementView(viewModel: viewModel, type: .genres)
        }
    }

    // MARK: - Item Tags

    @ViewBuilder
    func makeEditTags(item: BaseItemDto) -> some View {
        EditItemElementView<String>(
            viewModel: TagEditorViewModel(item: item),
            type: .tags,
            route: { router, viewModel in
                router.route(to: \.addTag, viewModel as! TagEditorViewModel)
            }
        )
    }

    func makeAddTag(viewModel: TagEditorViewModel) -> NavigationViewCoordinator<BasicNavigationViewCoordinator> {
        NavigationViewCoordinator {
            AddItemElementView(viewModel: viewModel, type: .tags)
        }
    }

    // MARK: - Item Studios

    @ViewBuilder
    func makeEditStudios(item: BaseItemDto) -> some View {
        EditItemElementView<NameGuidPair>(
            viewModel: StudioEditorViewModel(item: item),
            type: .studios,
            route: { router, viewModel in
                router.route(to: \.addStudio, viewModel as! StudioEditorViewModel)
            }
        )
    }

    func makeAddStudio(viewModel: StudioEditorViewModel) -> NavigationViewCoordinator<BasicNavigationViewCoordinator> {
        NavigationViewCoordinator {
            AddItemElementView(viewModel: viewModel, type: .studios)
        }
    }

    // MARK: - Item People

    @ViewBuilder
    func makeEditPeople(item: BaseItemDto) -> some View {
        EditItemElementView<BaseItemPerson>(
            viewModel: PeopleEditorViewModel(item: item),
            type: .people,
            route: { router, viewModel in
                router.route(to: \.addPeople, viewModel as! PeopleEditorViewModel)
            }
        )
    }

    func makeAddPeople(viewModel: PeopleEditorViewModel) -> NavigationViewCoordinator<BasicNavigationViewCoordinator> {
        NavigationViewCoordinator {
            AddItemElementView(viewModel: viewModel, type: .people)
        }
    }

    // MARK: - Start

    @ViewBuilder
    func makeStart() -> some View {
        ItemEditorView(viewModel: viewModel)
    }
}
