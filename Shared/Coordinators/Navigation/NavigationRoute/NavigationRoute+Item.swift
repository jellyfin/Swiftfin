//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension NavigationRoute {

    // MARK: - Item Editing

    #if os(iOS)
    static func addItemElement<Editor: ItemComponentEditor>(
        viewModel: ItemComponentEditorViewModel<Editor>
    ) -> NavigationRoute {
        NavigationRoute(
            id: "addItemElement-\(Editor.self)",
            style: .sheet
        ) {
            AddItemElementView(viewModel: viewModel)
        }
    }
    #endif

    @MainActor
    static func castAndCrew(people: [BaseItemPerson], itemID: String?) -> NavigationRoute {
        let id = itemID == nil ? "castAndCrew" : "castAndCrew-\(itemID!)"
        let library = StaticLibrary(
            title: L10n.castAndCrew.localizedCapitalized,
            id: id,
            elements: people
        )

        return NavigationRoute(id: "castAndCrew") {
            PagingLibraryView(library: library)
        }
    }

    #if os(iOS)
    @MainActor
    static func editGenres(item: BaseItemDto) -> NavigationRoute {
        NavigationRoute(id: "editGenres") {
            EditItemElementView(
                viewModel: ItemComponentEditorViewModel(
                    editor: GenreComponentEditor(),
                    item: item
                )
            )
        }
    }

    @MainActor
    static func editMetadata(viewModel: ItemEditorViewModel) -> NavigationRoute {
        NavigationRoute(
            id: "editMetadata",
            style: .sheet
        ) {
            EditMetadataView(viewModel: viewModel)
        }
    }

    @MainActor
    static func editPeople(item: BaseItemDto) -> NavigationRoute {
        NavigationRoute(id: "editPeople") {
            EditItemElementView(
                viewModel: ItemComponentEditorViewModel(
                    editor: PeopleComponentEditor(),
                    item: item
                )
            )
        }
    }

    @MainActor
    static func editStudios(item: BaseItemDto) -> NavigationRoute {
        NavigationRoute(id: "editStudios") {
            EditItemElementView(
                viewModel: ItemComponentEditorViewModel(
                    editor: StudioComponentEditor(),
                    item: item
                )
            )
        }
    }

    static func editSubtitles(item: BaseItemDto) -> NavigationRoute {
        NavigationRoute(
            id: "editSubtitles",
            style: .sheet
        ) {
            ItemSubtitlesView(item: item)
        }
    }

    @MainActor
    static func editTags(item: BaseItemDto) -> NavigationRoute {
        NavigationRoute(id: "editTags") {
            EditItemElementView(
                viewModel: ItemComponentEditorViewModel(
                    editor: TagComponentEditor(),
                    item: item
                )
            )
        }
    }

    static func identifyItem(item: BaseItemDto) -> NavigationRoute {
        NavigationRoute(id: "identifyItem") {
            IdentifyItemView(item: item)
        }
    }

    static func identifyItemResults(
        viewModel: IdentifyItemViewModel,
        result: RemoteSearchResult
    ) -> NavigationRoute {
        NavigationRoute(
            id: "identifyItemResults",
            style: .sheet
        ) {
            IdentifyItemResultView(
                viewModel: viewModel,
                result: result
            )
        }
    }

    static func uploadSubtitle(viewModel: ItemSubtitlesViewModel) -> NavigationRoute {
        NavigationRoute(
            id: "uploadSubtitle",
            style: .sheet
        ) {
            ItemSubtitleUploadView(viewModel: viewModel)
        }
    }

    #endif

    static func searchSubtitle(viewModel: ItemSubtitlesViewModel) -> NavigationRoute {
        NavigationRoute(
            id: "searchSubtitle",
            style: .sheet
        ) {
            ItemSubtitleSearchView(viewModel: viewModel)
        }
    }

    static func item(item: BaseItemDto) -> NavigationRoute {
        NavigationRoute(
            id: "item-\(item.id ?? "Unknown")",
            withNamespace: { .push(.zoom(sourceID: "item", namespace: $0)) }
        ) {
            ItemView(item: item)
        }
    }

    static func item(id: String) -> NavigationRoute {
        NavigationRoute(
            id: "item-\(id)",
            withNamespace: { .push(.zoom(sourceID: "item", namespace: $0)) }
        ) {
            ItemView(item: .init(id: id))
        }
    }

    #if os(iOS)
    static func itemEditor(viewModel: ItemEditorViewModel) -> NavigationRoute {
        NavigationRoute(
            id: "itemEditor",
            style: .sheet
        ) {
            ItemEditorView(viewModel: viewModel)
        }
    }

    static func itemImages(viewModel: ItemImageViewModel) -> NavigationRoute {
        NavigationRoute(
            id: "itemImages",
            style: .sheet
        ) {
            ItemImagesView(viewModel: viewModel)
        }
    }

    static func itemImageDetail(viewModel: ItemImageViewModel, imageInfo: ImageInfo) -> NavigationRoute {
        NavigationRoute(
            id: "itemImageDetail",
            style: .sheet
        ) {
            ItemImageDetailView(
                viewModel: viewModel,
                imageInfo: imageInfo
            )
        }
    }

    static func remoteImageDetail(
        viewModel: ItemImageViewModel,
        remoteImageInfo: RemoteImageInfo
    ) -> NavigationRoute {
        NavigationRoute(
            id: "remoteImageDetail",
            withNamespace: { .push(.zoom(sourceID: "item", namespace: $0)) }
        ) {
            RemoteImageDetailView(
                viewModel: viewModel,
                remoteImageInfo: remoteImageInfo
            )
        }
    }

    static func remoteImageSearch(viewModel: ItemImageViewModel, imageType: ImageType) -> NavigationRoute {
        NavigationRoute(
            id: "remoteImageSearch",
            style: .sheet
        ) {
            RemoteImageSearchView(viewModel: viewModel, imageType: imageType)
        }
    }

    #endif

    static func itemMetadataRefresh(viewModel: ItemEditorViewModel) -> NavigationRoute {
        NavigationRoute(
            id: "itemMetadataRefresh",
            style: .sheet
        ) {
            ItemRefreshView(viewModel: viewModel)
        }
    }

    static func itemOverview(item: BaseItemDto) -> NavigationRoute {
        NavigationRoute(
            id: "itemOverview",
            style: .sheet
        ) {
            ItemOverviewView(item: item)
        }
    }
}
