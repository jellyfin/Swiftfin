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
import JellyfinAPI
import SwiftUI

struct AddItemImageView: View {

    // MARK: - Observed, & Environment Objects

    @EnvironmentObject
    private var router: ItemImagesCoordinator.Router

    @ObservedObject
    private var viewModel: ItemImagesViewModel

    @StateObject
    private var remoteImageInfoViewModel: RemoteImageInfoViewModel

    // MARK: - Dialog State

    @State
    private var selectedImage: RemoteImageInfo?
    @State
    private var error: Error?

    // MARK: - Collection Layout

    @State
    private var layout: CollectionVGridLayout = .minWidth(150)

    // MARK: - Initializer

    init(viewModel: ItemImagesViewModel, imageType: ImageType) {
        self.viewModel = viewModel
        self._remoteImageInfoViewModel = StateObject(wrappedValue: RemoteImageInfoViewModel(
            item: viewModel.item,
            imageType: imageType
        ))
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            switch remoteImageInfoViewModel.state {
            case .initial, .refreshing:
                DelayedProgressView()
            case .content:
                gridView
            case let .error(error):
                ErrorView(error: error)
                    .onRetry {
                        viewModel.send(.refresh)
                    }
            }
        }
        .navigationTitle(remoteImageInfoViewModel.imageType.displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(viewModel.state == .updating)
        .topBarTrailing {
            if viewModel.backgroundStates.contains(.refreshing) {
                ProgressView()
            }
        }
        .sheet(item: $selectedImage) {
            selectedImage = nil
        } content: { remoteImageInfo in
            ItemImageDetailsView(
                viewModel: viewModel,
                imageSource: ImageSource(url: URL(string: remoteImageInfo.url)),
                width: remoteImageInfo.width,
                height: remoteImageInfo.height,
                language: remoteImageInfo.language,
                provider: remoteImageInfo.providerName,
                rating: remoteImageInfo.communityRating,
                ratingType: remoteImageInfo.ratingType,
                ratingVotes: remoteImageInfo.voteCount,
                onClose: {
                    selectedImage = nil
                },
                onSave: {
                    viewModel.send(.setImage(remoteImageInfo))
                    selectedImage = nil
                }
            )
            .navigationTitle(remoteImageInfo.type?.displayTitle ?? "")
            .environment(\.isEditing, true)
        }
        .onFirstAppear {
            remoteImageInfoViewModel.send(.refresh)
        }
        .onReceive(viewModel.events) { event in
            switch event {
            case .deleted:
                break
            case .updated:
                UIDevice.feedback(.success)
                router.pop()
            case let .error(eventError):
                UIDevice.feedback(.error)
                error = eventError
            }
        }
        .errorMessage($error)
    }

    // MARK: - Content Grid View

    @ViewBuilder
    private var gridView: some View {
        if remoteImageInfoViewModel.elements.isEmpty {
            Text(L10n.none)
        } else {
            CollectionVGrid(
                uniqueElements: remoteImageInfoViewModel.elements,
                layout: layout
            ) { image in
                imageButton(image)
            }
            .onReachedBottomEdge(offset: .offset(300)) {
                remoteImageInfoViewModel.send(.getNextPage)
            }
        }
    }

    // MARK: - Poster Image Button

    @ViewBuilder
    private func imageButton(_ image: RemoteImageInfo?) -> some View {
        Button {
            if let image {
                selectedImage = image
            }
        } label: {
            posterImage(
                image,
                posterStyle: image?.height ?? 0 > image?.width ?? 0 ? .portrait : .landscape
            )
        }
    }

    // MARK: - Poster Image

    @ViewBuilder
    private func posterImage(
        _ posterImageInfo: RemoteImageInfo?,
        posterStyle: PosterDisplayType
    ) -> some View {
        ZStack {
            Color.secondarySystemFill
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            ImageView(URL(string: posterImageInfo?.url ?? ""))
                .placeholder { source in
                    if let blurHash = source.blurHash {
                        BlurHashView(blurHash: blurHash, size: .Square(length: 8))
                            .scaledToFit()
                    } else {
                        Image(systemName: "circle")
                    }
                }
                .failure {
                    Image(systemName: "questionmark")
                }
                .foregroundColor(.secondary)
                .font(.headline)
        }
        .posterStyle(posterStyle)
    }
}
