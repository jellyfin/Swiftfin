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
    static func addGenre(viewModel: GenreEditorViewModel) -> NavigationRoute {
        NavigationRoute(
            id: "addGenre",
            style: .sheet
        ) {
            AddItemElementView(viewModel: viewModel, type: .genres)
        }
    }

    static func addPeople(viewModel: PeopleEditorViewModel) -> NavigationRoute {
        NavigationRoute(
            id: "addPeople",
            style: .sheet
        ) {
            AddItemElementView(viewModel: viewModel, type: .people)
        }
    }

    static func addStudio(viewModel: StudioEditorViewModel) -> NavigationRoute {
        NavigationRoute(
            id: "addStudio",
            style: .sheet
        ) {
            AddItemElementView(viewModel: viewModel, type: .studios)
        }
    }

    static func addTag(viewModel: TagEditorViewModel) -> NavigationRoute {
        NavigationRoute(
            id: "addTag",
            style: .sheet
        ) {
            AddItemElementView(viewModel: viewModel, type: .tags)
        }
    }
    #endif

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

    #if os(iOS)
    @MainActor
    static func editGenres(item: BaseItemDto) -> NavigationRoute {
        NavigationRoute(id: "editGenres") {
            EditItemElementView<String>(
                viewModel: GenreEditorViewModel(item: item),
                type: .genres,
                route: { router, viewModel in
                    router.route(to: .addGenre(viewModel: viewModel as! GenreEditorViewModel))
                }
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

    static func uploadSubtitle(viewModel: SubtitleEditorViewModel) -> NavigationRoute {
        NavigationRoute(
            id: "uploadSubtitle",
            style: .sheet
        ) {
            ItemSubtitleUploadView(viewModel: viewModel)
        }
    }

    @MainActor
    static func editMetadata(viewModel: ItemEditorViewModel<BaseItemDto>) -> NavigationRoute {
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
            EditItemElementView<BaseItemPerson>(
                viewModel: PeopleEditorViewModel(item: item),
                type: .people,
                route: { router, viewModel in
                    router.route(to: .addPeople(viewModel: viewModel as! PeopleEditorViewModel))
                }
            )
        }
    }

    @MainActor
    static func editStudios(item: BaseItemDto) -> NavigationRoute {
        NavigationRoute(id: "editStudios") {
            EditItemElementView<NameGuidPair>(
                viewModel: StudioEditorViewModel(item: item),
                type: .studios,
                route: { router, viewModel in
                    router.route(to: .addStudio(viewModel: viewModel as! StudioEditorViewModel))
                }
            )
        }
    }

    @MainActor
    static func editTags(item: BaseItemDto) -> NavigationRoute {
        NavigationRoute(id: "editTags") {
            EditItemElementView<String>(
                viewModel: TagEditorViewModel(item: item),
                type: .tags,
                route: { router, viewModel in
                    router.route(to: .addTag(viewModel: viewModel as! TagEditorViewModel))
                }
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
    #endif

    static func searchSubtitle(viewModel: SubtitleEditorViewModel) -> NavigationRoute {
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

    #if os(iOS)
    static func itemEditor(viewModel: ItemEditorViewModel<BaseItemDto>) -> NavigationRoute {
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
            style: .push(.automatic)
        ) {
            ItemImagesView(viewModel: viewModel)
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

    static func itemMetadataRefresh(viewModel: ItemEditorViewModel<BaseItemDto>) -> NavigationRoute {
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
