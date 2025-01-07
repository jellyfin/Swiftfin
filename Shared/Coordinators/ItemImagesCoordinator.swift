//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Factory
import JellyfinAPI
import Stinsen
import SwiftUI

final class ItemImagesCoordinator: ObservableObject, NavigationCoordinatable {

    // MARK: - User Session

    @Injected(\.currentUserSession)
    private var userSession

    // MARK: - Navigation Stack

    let stack = NavigationStack(initial: \ItemImagesCoordinator.start)

    @Root
    var start = makeStart

    @ObservedObject
    private var viewModel: ItemImagesViewModel

    // MARK: - Route to Delete Local Image

    @Route(.modal)
    var deleteImage = makeDeleteImage

    // MARK: - Route to Add Remote Image

    @Route(.push)
    var addImage = makeAddImage
    @Route(.modal)
    var selectImage = makeSelectImage

    // MARK: - Route to Photo Picker

    @Route(.modal)
    var photoPicker = makePhotoPicker

    // MARK: - Initializer

    init(viewModel: ItemImagesViewModel) {
        self._viewModel = ObservedObject(wrappedValue: viewModel)
    }

    // MARK: - Add Remote Images View

    @ViewBuilder
    func makeAddImage(imageType: ImageType) -> some View {
        AddItemImageView(viewModel: viewModel, imageType: imageType)
    }

    func makeSelectImage(remoteImageInfo: RemoteImageInfo) -> NavigationViewCoordinator<BasicNavigationViewCoordinator> {
        NavigationViewCoordinator {
            ItemImageDetailsView(
                title: remoteImageInfo.type?.displayTitle ?? "",
                viewModel: self.viewModel,
                imageSource: ImageSource(url: URL(string: remoteImageInfo.url)),
                width: remoteImageInfo.width,
                height: remoteImageInfo.height,
                language: remoteImageInfo.language,
                provider: remoteImageInfo.providerName,
                rating: remoteImageInfo.communityRating,
                ratingType: remoteImageInfo.ratingType,
                ratingVotes: remoteImageInfo.voteCount,
                isLocal: false,
                onSave: {
                    self.viewModel.send(.setImage(remoteImageInfo))
                }
            )
        }
    }

    // MARK: - Delete Local Image View

    func makeDeleteImage(imageInfo: ImageInfo) -> NavigationViewCoordinator<BasicNavigationViewCoordinator> {
        NavigationViewCoordinator {
            ItemImageDetailsView(
                title: imageInfo.imageType?.displayTitle ?? "",
                viewModel: self.viewModel,
                imageSource: imageInfo.itemImageSource(
                    itemID: self.viewModel.item.id!,
                    client: self.userSession!.client
                ),
                index: imageInfo.imageIndex,
                width: imageInfo.width,
                height: imageInfo.height,
                isLocal: true,
                onDelete: {
                    self.viewModel.send(.deleteImage(imageInfo))
                }
            )
        }
    }

    // MARK: - Photo Picker View

    func makePhotoPicker(type: ImageType) -> NavigationViewCoordinator<ItemImagePickerCoordinator> {
        NavigationViewCoordinator(ItemImagePickerCoordinator(viewModel: self.viewModel, type: type))
    }

    // MARK: - Start

    @ViewBuilder
    func makeStart() -> some View {
        ItemImagesView(viewModel: self.viewModel)
    }
}
