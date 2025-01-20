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

    // MARK: - Navigation Stack

    let stack = NavigationStack(initial: \ItemImagesCoordinator.start)

    @Root
    var start = makeStart

    private let viewModel: ItemImagesViewModel

    // MARK: - Route to Add Remote Image

    @Route(.push)
    var addImage = makeAddImage

    // MARK: - Route to Photo Picker

    @Route(.modal)
    var photoPicker = makePhotoPicker

    // MARK: - Initializer

    init(viewModel: ItemImagesViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Add Remote Images View

    @ViewBuilder
    func makeAddImage(imageType: ImageType) -> some View {
        AddItemImageView(viewModel: viewModel, imageType: imageType)
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
