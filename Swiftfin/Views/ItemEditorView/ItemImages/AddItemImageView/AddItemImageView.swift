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
import SwiftUI

struct AddItemImageView: View {

    // MARK: - Defaults

    @Default(.accentColor)
    private var accentColor

    // MARK: - State, Observed, & Environment Objects

    @EnvironmentObject
    private var router: ItemEditorCoordinator.Router

    @ObservedObject
    private var viewModel: ItemImagesViewModel

    @StateObject
    private var remoteImageInfoViewModel: RemoteImageInfoViewModel

    // MARK: - Dialog States

    @State
    private var error: Error?

    // MARK: - Selected Image

    @State
    private var selectedImage: RemoteImageInfo?

    // MARK: - Collection Layout

    @State
    private var layout: CollectionVGridLayout = .minWidth(150)

    // MARK: - Initializer

    init(viewModel: ItemImagesViewModel) {
        self._viewModel = ObservedObject(wrappedValue: viewModel)
        self._remoteImageInfoViewModel = StateObject(wrappedValue: RemoteImageInfoViewModel(
            item: viewModel.item,
            imageType: viewModel.selectedType!
        ))
    }

    // MARK: - Body

    var body: some View {
        contentView
            .navigationBarTitle(remoteImageInfoViewModel.imageType.rawValue.localizedCapitalized)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(viewModel.state == .updating)
            .topBarTrailing {
                if viewModel.backgroundStates.contains(.refreshing) {
                    ProgressView()
                }
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
            .sheet(item: $selectedImage, onDismiss: {
                selectedImage = nil
            }) { selectedImage in
                confirmationSheet(selectedImage)
            }
    }

    // MARK: - Content View

    @ViewBuilder
    private var contentView: some View {
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

    // MARK: - Content Grid View

    @ViewBuilder
    private var gridView: some View {
        if viewModel.images.isEmpty {
            Text(L10n.none)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .listRowSeparator(.hidden)
                .listRowInsets(.zero)
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
                posterStyle: image?.height ?? 0 > image?.width ?? 0 ? .portrait : .landscape
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
        .posterStyle(posterStyle)
    }

    // MARK: - Set Image Confirmation

    @ViewBuilder
    private func confirmationSheet(_ remoteImageInfo: RemoteImageInfo) -> some View {
        NavigationView {
            VStack {
                posterImage(
                    remoteImageInfo,
                    posterStyle: remoteImageInfo.height ?? 0 > remoteImageInfo.width ?? 0 ? .portrait : .landscape
                )
                .scaledToFit()

                if let imageWidth = remoteImageInfo.width, let imageHeight = remoteImageInfo.height {
                    Text("\(imageWidth) x \(imageHeight)")
                        .font(.body)
                }

                Text(remoteImageInfo.providerName ?? .emptyDash)
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
                    viewModel.send(.setImage(remoteImageInfo))
                }
                .buttonStyle(.toolbarPill)
            }
        }
    }
}
