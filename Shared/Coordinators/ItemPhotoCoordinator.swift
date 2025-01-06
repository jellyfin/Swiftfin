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

final class ItemPhotoCoordinator: NavigationCoordinatable {

    // MARK: - Navigation Components

    let stack = Stinsen.NavigationStack(initial: \ItemPhotoCoordinator.start)

    @Root
    var start = makeStart

    // MARK: - Routes

    @Route(.push)
    var cropImage = makeCropImage

    // MARK: - Observed Object

    @ObservedObject
    var viewModel: ItemImagesViewModel

    let type: ImageType

    // MARK: - Initializer

    init(viewModel: ItemImagesViewModel, type: ImageType) {
        self.viewModel = viewModel
        self.type = type
    }

    // MARK: - Views

    func makeCropImage(image: UIImage) -> some View {
        #if os(iOS)
        ItemImagePicker.ImageCropView(viewModel: viewModel, image: image, type: type)
        #else
        AssertionFailureView("not implemented")
        #endif
    }

    @ViewBuilder
    func makeStart() -> some View {
        #if os(iOS)
        ItemImagePicker()
        #else
        AssertionFailureView("not implemented")
        #endif
    }
}
