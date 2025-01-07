//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import Mantis
import SwiftUI

struct ItemPhotoCropView: View {

    // MARK: - State, Observed, & Environment Objects

    @EnvironmentObject
    private var router: ItemImagePickerCoordinator.Router

    @ObservedObject
    var viewModel: ItemImagesViewModel

    // MARK: - Image Variable

    let image: UIImage
    let type: ImageType

    // MARK: - Error State

    @State
    private var error: Error?

    // MARK: - Body

    var body: some View {
        PhotoCropView(
            isSaving: viewModel.state == .updating,
            image: image,
            cropShape: .rect,
            presetRatio: .canUseMultiplePresetFixedRatio()
        ) {
            viewModel.send(.uploadPhoto(image: $0, type: type))
        } onCancel: {
            router.dismissCoordinator()
        }
        .animation(.linear(duration: 0.1), value: viewModel.state)
        .interactiveDismissDisabled(viewModel.state == .updating)
        .navigationBarBackButtonHidden(viewModel.state == .updating)
        .onReceive(viewModel.events) { event in
            switch event {
            case let .error(eventError):
                error = eventError
            case .deleted:
                break
            case .updated:
                router.dismissCoordinator()
            }
        }
        .errorMessage($error)
    }
}
