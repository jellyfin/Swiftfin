//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import BlurHashKit
import CollectionVGrid
import Combine
import Defaults
import JellyfinAPI
import Nuke
import SwiftUI

struct ItemImageDetailsView: View {

    // MARK: - Defaults

    @Default(.accentColor)
    private var accentColor

    // MARK: - State, Observed, & Environment Objects

    @EnvironmentObject
    private var router: BasicNavigationViewCoordinator.Router

    @ObservedObject
    var viewModel: ItemImagesViewModel

    // MARK: - Image Variable

    private let localImageInfo: (key: ImageInfo, value: UIImage)?

    private let remoteImageInfo: RemoteImageInfo?

    // MARK: - Dialog States

    @State
    private var error: Error?

    // MARK: - Collection Layout

    @State
    private var layout: CollectionVGridLayout = .minWidth(150)

    // MARK: - Initializer

    init(viewModel: ItemImagesViewModel, localImageInfo: (key: ImageInfo, value: UIImage)? = nil, remoteImageInfo: RemoteImageInfo? = nil) {
        self._viewModel = ObservedObject(wrappedValue: viewModel)
        self.localImageInfo = localImageInfo
        self.remoteImageInfo = remoteImageInfo
    }

    // MARK: - Body

    var body: some View {
        contentView
            .navigationBarTitle(
                localImageInfo?.key.imageType?.rawValue.localizedCapitalized ??
                    remoteImageInfo?.type?.rawValue.localizedCapitalized ??
                    ""
            )
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarCloseButton {
                router.dismissCoordinator()
            }
            .topBarTrailing {
                if viewModel.backgroundStates.contains(.refreshing) {
                    ProgressView()
                }
            }
            .onReceive(viewModel.events) { event in
                switch event {
                case .deleted:
                    UIDevice.feedback(.success)
                    router.dismissCoordinator()
                case .updated:
                    break
                case let .error(eventError):
                    UIDevice.feedback(.error)
                    error = eventError
                }
            }
            .errorMessage($error)
    }

    // MARK: - Content View

    @ViewBuilder
    var contentView: some View {
        if let imageInfo = localImageInfo {
            LocalImageInfoView(imageInfo: imageInfo.key, image: imageInfo.value) {
                viewModel.send(.deleteImage(imageInfo.key))
            }
        } else if let imageInfo = remoteImageInfo {
            RemoteImageInfoView(imageInfo: imageInfo) {
                viewModel.send(.setImage(imageInfo))
            }
        } else {
            ErrorView(error: JellyfinAPIError("No image provided."))
        }
    }
}
