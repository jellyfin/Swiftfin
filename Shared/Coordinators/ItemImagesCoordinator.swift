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

final class ItemImagesCoordinator: ObservableObject, NavigationCoordinatable {

    let stack = NavigationStack(initial: \ItemImagesCoordinator.start)

    @Root
    var start = makeStart

    @ObservedObject
    private var viewModel: ItemImagesViewModel

    // MARK: - Route to Views

    @Route(.push)
    var addImage = makeAddImage
    @Route(.modal)
    var deleteImage = makeDeleteImage
    @Route(.modal)
    var selectImage = makeSelectImage

    // MARK: - Initializer

    init(viewModel: ItemImagesViewModel) {
        self._viewModel = ObservedObject(wrappedValue: viewModel)
    }

    // MARK: - Item Images

    @ViewBuilder
    func makeAddImage(imageType: ImageType) -> some View {
        AddItemImageView(viewModel: viewModel, imageType: imageType)
    }

    func makeDeleteImage(imageInfo: (key: ImageInfo, value: UIImage)) -> NavigationViewCoordinator<BasicNavigationViewCoordinator> {
        NavigationViewCoordinator {
            ItemImageDetailsView(viewModel: self.viewModel, localImageInfo: imageInfo)
        }
    }

    func makeSelectImage(remoteImageInfo: RemoteImageInfo) -> NavigationViewCoordinator<BasicNavigationViewCoordinator> {
        NavigationViewCoordinator {
            ItemImageDetailsView(viewModel: self.viewModel, remoteImageInfo: remoteImageInfo)
        }
    }

    // MARK: - Start

    @ViewBuilder
    func makeStart() -> some View {
        ItemImagesView(viewModel: self.viewModel)
    }
}
