//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct ItemImageDetailsView: View {

    // MARK: - Editing State

    @Environment(\.isEditing)
    private var isEditing

    // MARK: - State, Observed, & Environment Objects

    @Router
    private var router

    @ObservedObject
    private var viewModel: ItemImagesViewModel

    // MARK: - Image Variable

    private let imageSource: ImageSource

    // MARK: - Description Variables

    private let index: Int?
    private let width: Int?
    private let height: Int?
    private let language: String?
    private let provider: String?
    private let rating: Double?
    private let ratingVotes: Int?

    // MARK: - Image Actions

    private let onSave: (() -> Void)?
    private let onDelete: (() -> Void)?

    // MARK: - Error State

    @State
    private var error: Error?

    // MARK: - Body

    var body: some View {
        contentView
            .navigationTitle(L10n.image)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarCloseButton {
                router.dismiss()
            }
            .topBarTrailing {
                if viewModel.backgroundStates.contains(.updating) {
                    ProgressView()
                }

                if !isEditing, let onSave {
                    Button(L10n.save) {
                        onSave()
                    }
                    .buttonStyle(.toolbarPill)
                }
            }
            .errorMessage($error)
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
    }

    // MARK: - Content View

    @ViewBuilder
    private var contentView: some View {
        List {
            HeaderSection(
                imageSource: imageSource,
                posterType: height ?? 0 > width ?? 0 ? .portrait : .landscape
            )

            DetailsSection(
                url: imageSource.url,
                index: index,
                language: language,
                width: width,
                height: height,
                provider: provider,
                rating: rating,
                ratingVotes: ratingVotes
            )

            if isEditing, let onDelete {
                DeleteButton {
                    onDelete()
                }
            }
        }
    }
}

extension ItemImageDetailsView {

    // Initialize as a Local Server Image

    init(
        viewModel: ItemImagesViewModel,
        imageInfo: ImageInfo
    ) {
        self.viewModel = viewModel
        self.imageSource = imageInfo.itemImageSource(
            itemID: viewModel.item.id!,
            client: viewModel.userSession.client
        )
        self.index = imageInfo.imageIndex
        self.width = imageInfo.width
        self.height = imageInfo.height
        self.language = nil
        self.provider = nil
        self.rating = nil
        self.ratingVotes = nil
        self.onSave = nil
        self.onDelete = {
            viewModel.send(.deleteImage(imageInfo))
        }
    }

    // Initialize as a Remote Search Image

    init(
        viewModel: ItemImagesViewModel,
        remoteImageInfo: RemoteImageInfo
    ) {
        self.viewModel = viewModel
        self.imageSource = ImageSource(url: remoteImageInfo.url?.url)
        self.index = nil
        self.width = remoteImageInfo.width
        self.height = remoteImageInfo.height
        self.language = remoteImageInfo.language
        self.provider = remoteImageInfo.providerName
        self.rating = remoteImageInfo.communityRating
        self.ratingVotes = remoteImageInfo.voteCount
        self.onSave = {
            viewModel.send(.setImage(remoteImageInfo))
        }
        self.onDelete = nil
    }
}
