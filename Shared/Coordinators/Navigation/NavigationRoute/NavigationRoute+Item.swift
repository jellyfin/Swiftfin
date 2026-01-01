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

    static func addItemImage(viewModel: ItemImagesViewModel, imageType: ImageType) -> NavigationRoute {
        NavigationRoute(
            id: "addItemImage",
            style: .push(.automatic)
        ) {
            AddItemImageView(
                viewModel: viewModel,
                imageType: imageType
            )
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
    static func cropItemImage(viewModel: ItemImagesViewModel, image: UIImage, type: ImageType) -> NavigationRoute {
        NavigationRoute(
            id: "crop-Image"
        ) {
            ItemPhotoCropView(
                viewModel: viewModel,
                image: image,
                type: type
            )
        }
    }

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
        NavigationRoute(id: "editSubtitles") {
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

    static func editMetadata(item: BaseItemDto) -> NavigationRoute {
        NavigationRoute(
            id: "editMetadata",
            style: .sheet
        ) {
            EditMetadataView(viewModel: ItemEditorViewModel(item: item))
        }
    }

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
            IdentifyItemView.RemoteSearchResultView(
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
    static func itemEditor(viewModel: ItemViewModel) -> NavigationRoute {
        NavigationRoute(
            id: "itemEditor",
            style: .sheet
        ) {
            ItemEditorView(viewModel: viewModel)
        }
    }

    static func itemImageDetails(viewModel: ItemImagesViewModel, imageInfo: ImageInfo) -> NavigationRoute {
        NavigationRoute(
            id: "itemImageDetails",
            style: .sheet
        ) {
            ItemImageDetailsView(
                viewModel: viewModel,
                imageInfo: imageInfo
            )
            .isEditing(true)
        }
    }

    static func itemImages(viewModel: ItemImagesViewModel) -> NavigationRoute {
        NavigationRoute(
            id: "itemImages",
            style: .sheet
        ) {
            ItemImagesView(viewModel: viewModel)
        }
    }

    static func itemImageSelector(viewModel: ItemImagesViewModel, imageType: ImageType) -> NavigationRoute {
        NavigationRoute(
            id: "itemImageSelector",
            style: .sheet
        ) {
            ItemImagePicker(
                viewModel: viewModel,
                type: imageType
            )
        }
    }
    #endif

    static func itemMetadataRefresh(viewModel: RefreshMetadataViewModel) -> NavigationRoute {
        NavigationRoute(
            id: "itemMetadataRefresh",
            style: .sheet
        ) {
            RefreshMetadataView(viewModel: viewModel)
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

    #if os(iOS)

    static func itemSearchImageDetails(viewModel: ItemImagesViewModel, remoteImageInfo: RemoteImageInfo) -> NavigationRoute {
        NavigationRoute(
            id: "itemSearchImageDetails",
            style: .sheet
        ) {
            ItemImageDetailsView(
                viewModel: viewModel,
                remoteImageInfo: remoteImageInfo
            )
            .isEditing(false)
        }
    }

    #endif
}
