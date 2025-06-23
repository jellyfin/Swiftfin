//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct UserProfileImagePickerView: View {

    // MARK: - Observed, & Environment Objects

    @Router
    private var router

    @StateObject
    var viewModel: UserProfileImageViewModel

    // MARK: - Body

    var body: some View {
        PhotoPickerView {
            router.route(to: .userProfileImageCrop(viewModel: viewModel, image: $0))
        } onCancel: {
            router.dismiss()
        }
    }
}
