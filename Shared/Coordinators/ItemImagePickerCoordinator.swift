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

final class ItemImagePickerCoordinator: NavigationCoordinatable {

    // MARK: - Navigation Stack

    let stack = Stinsen.NavigationStack(initial: \ItemImagePickerCoordinator.start)

    @Root
    var start = makeStart

    // MARK: - Routes

    @Route(.push)
    var cropImage = makeCropImage

    // MARK: - Observed Object

    private let viewModel: ItemImagesViewModel

    // MARK: - Image Variable

    let type: ImageType

    // MARK: - Initializer

    init(viewModel: ItemImagesViewModel, type: ImageType) {
        self.viewModel = viewModel
        self.type = type
    }

    // MARK: - Crop Image View

    func makeCropImage(image: UIImage) -> some View {
        ItemPhotoCropView(viewModel: viewModel, image: image, type: type)
    }

    @ViewBuilder
    func makeStart() -> some View {
        ItemImagePicker()
    }
}
