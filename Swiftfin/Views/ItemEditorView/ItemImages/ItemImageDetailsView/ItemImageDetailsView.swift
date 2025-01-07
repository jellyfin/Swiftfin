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

    private let localImageInfo: (key: ImageInfo, value: URL)?

    private let remoteImageInfo: RemoteImageInfo?

    // MARK: - Dialog States

    @State
    private var error: Error?

    // MARK: - Collection Layout

    @State
    private var layout: CollectionVGridLayout = .minWidth(150)

    // MARK: - Initializer

    init(viewModel: ItemImagesViewModel, localImageInfo: (key: ImageInfo, value: URL)? = nil, remoteImageInfo: RemoteImageInfo? = nil) {
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
                case .deleted, .updated:
                    UIDevice.feedback(.success)
                    router.dismissCoordinator()
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
            localImageView(imageInfo: imageInfo.key, imageURL: imageInfo.value)
        } else if let imageInfo = remoteImageInfo {
            remoteImageView(imageInfo: imageInfo)
        } else {
            ErrorView(error: JellyfinAPIError("No image provided."))
        }
    }

    @ViewBuilder
    func localImageView(imageInfo: ImageInfo, imageURL: URL) -> some View {
        List {
            HeaderSection(
                imageURL: imageURL,
                imageType: imageInfo.height ?? 0 > imageInfo.width ?? 0 ? .portrait : .landscape
            )
            DetailsSection(
                imageID: imageInfo.id,
                imageURL: imageURL,
                imageIndex: imageInfo.imageIndex,
                imageWidth: imageInfo.width,
                imageHeight: imageInfo.height
            )
            DeleteButton {
                viewModel.send(.deleteImage(imageInfo))
            }
        }
    }

    @ViewBuilder
    func remoteImageView(imageInfo: RemoteImageInfo) -> some View {
        let imageURL = URL(string: imageInfo.url)

        List {
            HeaderSection(
                imageURL: URL(string: imageInfo.url),
                imageType: imageInfo.height ?? 0 > imageInfo.width ?? 0 ? .portrait : .landscape
            )
            DetailsSection(
                imageID: imageInfo.id,
                imageURL: imageURL,
                imageLanguage: imageInfo.language,
                imageWidth: imageInfo.width,
                imageHeight: imageInfo.height,
                provider: imageInfo.providerName,
                rating: imageInfo.communityRating,
                ratingType: imageInfo.ratingType,
                ratingVotes: imageInfo.voteCount
            )
        }
        .topBarTrailing {
            Button(L10n.save) {
                viewModel.send(.setImage(imageInfo))
            }
            .buttonStyle(.toolbarPill)
        }
    }
}
