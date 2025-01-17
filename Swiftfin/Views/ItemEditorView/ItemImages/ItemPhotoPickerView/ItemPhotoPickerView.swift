//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct ItemImagePicker: View {

    // MARK: - Observed, & Environment Objects

    @EnvironmentObject
    private var router: ItemImagePickerCoordinator.Router

    // MARK: - Body

    var body: some View {
        PhotoPickerView {
            router.route(to: \.cropImage, $0)
        } onCancel: {
            router.dismissCoordinator()
        }
    }
}
