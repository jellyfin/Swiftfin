//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import BlurHashKit
import CollectionVGrid
import Combine
import Defaults
import JellyfinAPI
import SwiftUI

struct AddItemImageView: View {

    // MARK: - Defaults

    @Default(.accentColor)
    private var accentColor

    // MARK: - State & Environment Objects

    @EnvironmentObject
    private var router: ItemEditorCoordinator.Router

    @StateObject
    var viewModel: ItemImagesViewModel

    // MARK: - Dialog States

    @State
    private var error: Error?

    // MARK: - Selected Image

    @State
    private var selectedImage: RemoteImageInfo?

    // MARK: - Collection Layout

    @State
    private var layout: CollectionVGridLayout = .minWidth(150)

    // MARK: - Body

    init(viewModel: ItemImagesViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        contentView
            .navigationBarTitle(viewModel.imageType?.rawValue.localizedCapitalized ?? L10n.unknown)
            .navigationBarTitleDisplayMode(.inline)
            .topBarTrailing {
                if viewModel.backgroundStates.contains(.refreshing) {
                    ProgramsView()
                }
            }
            .onFirstAppear {
                if viewModel.state == .initial {
                    viewModel.send(.getImages)
                }
            }
            .onReceive(viewModel.events) { event in
                switch event {
                case .updated:
                    UIDevice.feedback(.success)
                    router.dismissCoordinator()
                case let .error(eventError):
                    UIDevice.feedback(.error)
                    error = eventError
                }
            }
            .errorMessage($error)
            .sheet(item: $selectedImage, onDismiss: {
                selectedImage = nil
            }) { selectedImage in
                confirmationSheet(selectedImage)
            }
    }

    // MARK: - Content View

    @ViewBuilder
    private var contentView: some View {
        switch viewModel.state {
        case .initial:
            DelayedProgressView()
        case .content:
            gridView
        case .updating:
            updateView
        case let .error(error):
            ErrorView(error: error)
                .onRetry {
                    viewModel.send(.getImages)
                }
        }
    }

    // MARK: - Content Grid View

    @ViewBuilder
    private var gridView: some View {
        if viewModel.remoteImages.isEmpty {
            Text(L10n.none)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .listRowSeparator(.hidden)
                .listRowInsets(.zero)
        } else {
            CollectionVGrid(
                uniqueElements: viewModel.remoteImages,
                layout: layout
            ) { image in
                imageButton(image)
                    .padding(.vertical, 4)
            }
            .onReachedBottomEdge(offset: .offset(300)) {
                viewModel.send(.getNextPage)
            }
        }
    }

    // MARK: - Update View

    @ViewBuilder
    var updateView: some View {
        VStack(alignment: .center, spacing: 16) {
            ProgressView()
            Button(L10n.cancel, role: .destructive) {
                viewModel.send(.cancel)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
        }
    }

    // MARK: - Poster Image Button

    private func imageButton(_ image: RemoteImageInfo?) -> some View {
        Button {
            selectedImage = image
        } label: {
            posterImage(
                image,
                posterStyle: .landscape // image?.height ?? 0 > image?.width ?? 0 ? .portrait : .landscape
            )
        }
    }

    // MARK: - Poster Image

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
                    VStack(spacing: 8) {
                        Image(systemName: "photo")
                        Text(L10n.none)
                    }
                }
                .foregroundColor(.secondary)
                .font(.headline)
        }
        .scaledToFit()
        .posterStyle(posterStyle)
    }

    // MARK: - Set Image Confirmation

    @ViewBuilder
    private func confirmationSheet(_ image: RemoteImageInfo) -> some View {
        NavigationView {
            VStack {
                posterImage(
                    image,
                    posterStyle: image.height ?? 0 > image.width ?? 0 ? .portrait : .landscape
                )
                .scaledToFit()

                if let imageWidth = image.width, let imageHeight = image.height {
                    Text("\(imageWidth) x \(imageHeight)")
                        .font(.body)
                }

                Text(image.providerName ?? .emptyDash)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .navigationTitle(L10n.replaceImages)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarCloseButton {
                selectedImage = nil
            }
            .topBarTrailing {
                Button(L10n.save) {
                    if let newURL = image.url {
                        viewModel.send(.setImage(url: newURL))
                    }
                    selectedImage = nil
                }
                .buttonStyle(.toolbarPill)
            }
        }
    }
}
