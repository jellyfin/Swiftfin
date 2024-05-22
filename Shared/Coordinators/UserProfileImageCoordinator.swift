//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Stinsen
import SwiftUI

final class UserProfileImageCoordinator: NavigationCoordinatable {

    let stack = Stinsen.NavigationStack(initial: \UserProfileImageCoordinator.start)

    @Root
    var start = makeStart

    @Route(.push)
    var cropImage = makeCropImage

    func makeCropImage(image: UIImage) -> some View {
        #if os(iOS)
        UserProfileImagePicker.SquareImageCropView(
            image: image
        )
        #else
        AssertionFailureView("not implemented")
        #endif
    }

    @ViewBuilder
    func makeStart() -> some View {
        #if os(iOS)
        UserProfileImagePicker()
        #else
        AssertionFailureView("not implemented")
        #endif
    }
}
