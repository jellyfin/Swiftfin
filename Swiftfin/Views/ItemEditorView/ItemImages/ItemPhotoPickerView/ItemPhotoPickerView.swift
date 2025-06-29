//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct ItemImagePicker: View {

    // MARK: - Observed, & Environment Objects

    @Router
    private var router

    @StateObject
    var viewModel: ItemImagesViewModel

    let type: ImageType

    // MARK: - Error State

    @State
    private var error: Error?

    // MARK: - Body

    var body: some View {
        PhotoPickerView {
            router.route(
                to: .cropItemImage(
                    viewModel: viewModel,
                    image: $0,
                    type: type
                )
            )
        } onCancel: {
            router.dismiss()
        }
        .onReceive(viewModel.events) { event in
            switch event {
            case let .error(eventError):
                UIDevice.feedback(.error)
                error = eventError
            case .updated:
                UIDevice.feedback(.success)
                router.dismiss()
            }
        }
        .errorMessage($error)
    }
}
