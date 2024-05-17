//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct UserProfileImagePicker: View {

    @EnvironmentObject
    private var router: UserProfileImageCoordinator.Router

    var body: some View {
        PhotoPicker {
            router.dismissCoordinator()
        } onSelectedImage: { image in
            router.route(to: \.cropImage, image)
        }
    }
}
