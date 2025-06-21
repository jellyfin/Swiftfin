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

    @Router
    private var router

    // MARK: - Body

    var body: some View {
        PhotoPickerView { _ in
            // TODO: Convert to NavigationRoute pattern - router.route(to: .cropImage(image: $0))
//            router.route(to: \.cropImage, $0)
        } onCancel: {
            // TODO: Implement dismiss functionality in new router system
            router.dismissCoordinator()
        }
    }
}
