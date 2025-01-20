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

struct UserProfileImageCropView: View {

    // MARK: - State, Observed, & Environment Objects

    @EnvironmentObject
    private var router: UserProfileImageCoordinator.Router

    @ObservedObject
    var viewModel: UserProfileImageViewModel

    // MARK: - Image Variable

    let image: UIImage

    // MARK: - Error State

    @State
    private var error: Error?

    // MARK: - Body

    var body: some View {
        PhotoCropView(
            isSaving: viewModel.state == .uploading,
            image: image,
            cropShape: .square,
            presetRatio: .alwaysUsingOnePresetFixedRatio(ratio: 1)
        ) {
            viewModel.send(.upload($0))
        } onCancel: {
            router.dismissCoordinator()
        }
        .animation(.linear(duration: 0.1), value: viewModel.state)
        .interactiveDismissDisabled(viewModel.state == .uploading)
        .navigationBarBackButtonHidden(viewModel.state == .uploading)
        .onReceive(viewModel.events) { event in
            switch event {
            case let .error(eventError):
                error = eventError
            case .deleted:
                break
            case .uploaded:
                router.dismissCoordinator()
            }
        }
        .errorMessage($error)
    }
}
