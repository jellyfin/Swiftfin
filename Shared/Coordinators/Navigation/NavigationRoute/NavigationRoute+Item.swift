//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension NavigationRoute {

    static func castAndCrew(people: [BaseItemPerson], itemID: String?) -> NavigationRoute {
        let id: String? = itemID == nil ? nil : "castAndCrew-\(itemID!)"
        let viewModel = PagingLibraryViewModel(
            title: L10n.castAndCrew,
            id: id,
            people
        )

        return NavigationRoute(id: "castAndCrew") {
            PagingLibraryView(viewModel: viewModel)
        }
    }

    static func item(item: BaseItemDto) -> NavigationRoute {
        NavigationRoute(
            id: "item-\(item.unwrappedIDHashOrZero)",
            routeType: .push(.zoom)
        ) {
            ItemView(item: item)
        }
    }

    #if !os(tvOS)
    static func itemEditor(viewModel: ItemViewModel) -> NavigationRoute {
        NavigationRoute(
            id: "itemEditor",
            routeType: .sheet
        ) {
            ItemEditorView(viewModel: viewModel)
        }
    }

    static func itemImages(viewModel: ItemImagesViewModel) -> NavigationRoute {
        NavigationRoute(
            id: "itemImages",
            routeType: .sheet
        ) {
            ItemImagesView(viewModel: viewModel)
        }
    }
    #endif

    static func itemOverview(item: BaseItemDto) -> NavigationRoute {
        NavigationRoute(
            id: "itemOverview",
            routeType: .sheet
        ) {
            ItemOverviewView(item: item)
        }
    }

    // MARK: - Item Editing

    #if !os(tvOS)
    static func addGenre(viewModel: GenreEditorViewModel) -> NavigationRoute {
        NavigationRoute(
            id: "addGenre",
            routeType: .sheet
        ) {
            AddItemElementView(viewModel: viewModel, type: .genres)
        }
    }

    static func addPeople(viewModel: PeopleEditorViewModel) -> NavigationRoute {
        NavigationRoute(
            id: "addPeople",
            routeType: .sheet
        ) {
            AddItemElementView(viewModel: viewModel, type: .people)
        }
    }

    static func addStudio(viewModel: StudioEditorViewModel) -> NavigationRoute {
        NavigationRoute(
            id: "addStudio",
            routeType: .sheet
        ) {
            AddItemElementView(viewModel: viewModel, type: .studios)
        }
    }

    static func addTag(viewModel: TagEditorViewModel) -> NavigationRoute {
        NavigationRoute(
            id: "addTag",
            routeType: .sheet
        ) {
            AddItemElementView(viewModel: viewModel, type: .tags)
        }
    }
    #endif

    static func editGenres(item: BaseItemDto) -> NavigationRoute {
        NavigationRoute(id: "editGenres") {
            // TODO: Update EditItemElementView to use new Router system
            // For now, this will need to be handled by ItemEditorCoordinator
            Text("Edit Genres - Migration needed")
                .navigationTitle(L10n.genres)
        }
    }

    #if !os(tvOS)
    static func editMetadata(item: BaseItemDto) -> NavigationRoute {
        NavigationRoute(
            id: "editMetadata",
            routeType: .sheet
        ) {
            EditMetadataView(viewModel: ItemEditorViewModel(item: item))
        }
    }
    #endif

    static func editPeople(item: BaseItemDto) -> NavigationRoute {
        NavigationRoute(id: "editPeople") {
            // TODO: Update EditItemElementView to use new Router system
            // For now, this will need to be handled by ItemEditorCoordinator
            Text("Edit People - Migration needed")
                .navigationTitle(L10n.people)
        }
    }

    static func editStudios(item: BaseItemDto) -> NavigationRoute {
        NavigationRoute(id: "editStudios") {
            // TODO: Update EditItemElementView to use new Router system
            // For now, this will need to be handled by ItemEditorCoordinator
            Text("Edit Studios - Migration needed")
                .navigationTitle(L10n.studios)
        }
    }

    static func editTags(item: BaseItemDto) -> NavigationRoute {
        NavigationRoute(id: "editTags") {
            // TODO: Update EditItemElementView to use new Router system
            // For now, this will need to be handled by ItemEditorCoordinator
            Text("Edit Tags - Migration needed")
                .navigationTitle(L10n.tags)
        }
    }

    #if !os(tvOS)
    static func identifyItem(item: BaseItemDto) -> NavigationRoute {
        NavigationRoute(id: "identifyItem") {
            IdentifyItemView(item: item)
        }
    }
    #endif
}
