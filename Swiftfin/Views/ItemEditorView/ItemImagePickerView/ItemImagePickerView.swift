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

struct ItemImagePickerView: View {

    // MARK: - Defaults and Environment

    @Default(.accentColor)
    private var accentColor

    @EnvironmentObject
    private var router: BasicNavigationViewCoordinator.Router

    // MARK: - ViewModel

    @ObservedObject
    var viewModel: RemoteItemImageViewModel

    // MARK: - Dialog States

    @State
    private var isPresentingConfirmation: Bool = false
    @State
    private var isPresentingDeletion: Bool = false
    @State
    private var isImportingFile: Bool = false
    @State
    private var isPresentingError: Bool = false
    @State
    private var error: Error?

    // MARK: - Selected Image

    @State
    private var selectedImage: RemoteImageInfo? {
        didSet {
            isPresentingConfirmation = selectedImage != nil
        }
    }

    // MARK: - Collection Layout

    @State
    private var layout: CollectionVGridLayout = .minWidth(150)

    // MARK: - Body

    var body: some View {
        contentView
            .navigationBarTitle(viewModel.imageType.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarCloseButton {
                router.dismissCoordinator()
            }
            .onFirstAppear {
                if viewModel.state == .initial {
                    viewModel.send(.refresh)
                }
            }
            .navigationBarMenuButton(
                isLoading: viewModel.backgroundStates.contains {
                    $0 == .refreshing || $0 == .updating
                }
            ) {
                menuContent()
            }
            .onReceive(viewModel.events) { event in
                handleEvent(event)
            }
            .fileImporter(
                isPresented: $isImportingFile,
                allowedContentTypes: [.image],
                allowsMultipleSelection: false
            ) { handleFileImport($0) }
            .alert(
                L10n.error,
                isPresented: $isPresentingError,
                presenting: error
            ) { error in
                Text(error.localizedDescription)
                Button(L10n.dismiss, role: .cancel) {
                    isPresentingError = false
                }
            }
            .confirmationDialog(
                L10n.save,
                isPresented: $isPresentingConfirmation,
                titleVisibility: .visible
            ) {
                confirmationDialogContent()
            }
            .confirmationDialog(
                L10n.delete,
                isPresented: $isPresentingDeletion,
                titleVisibility: .visible
            ) {
                deletionDialogContent()
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
                uniqueElements: viewModel.images,
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
        VStack {
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

            if let imageWidth = posterImageInfo?.width, let imageHeight = posterImageInfo?.height {
                Text("\(imageWidth) x \(imageHeight)")
                    .font(.body)
            }

            Text(posterImageInfo?.providerName ?? .emptyDash)
                .font(.caption)
        }
        .foregroundStyle(Color.secondary)
    }

    // MARK: - Set Image Dialog

    @ViewBuilder
    private func confirmationDialogContent() -> some View {
        Button(L10n.confirm) {
            if let newURL = selectedImage?.url {
                viewModel.send(.setImage(url: newURL))
            }
            selectedImage = nil
        }
        Button(L10n.cancel, role: .cancel) {
            selectedImage = nil
        }
    }

    // MARK: - Delete Image Dialog

    @ViewBuilder
    private func deletionDialogContent() -> some View {
        Button(L10n.delete, role: .destructive) {
            viewModel.send(.deleteImage)
            isPresentingDeletion = false
            router.dismissCoordinator()
        }
        Button(L10n.cancel, role: .cancel) {
            isPresentingDeletion = false
        }
    }

    // MARK: - Handle ViewModel Events

    private func handleEvent(_ event: RemoteItemImageViewModel.Event) {
        switch event {
        case .updated:
            UIDevice.feedback(.success)
            router.dismissCoordinator()
        case let .error(eventError):
            UIDevice.feedback(.error)
            error = eventError
            isPresentingError = true
        }
    }

    // MARK: - Handle File Importing

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case let .success(urls):
            if let url = urls.first {
                guard url.startAccessingSecurityScopedResource() else { return }
                defer { url.stopAccessingSecurityScopedResource() }

                do {
                    let fileData = try Data(contentsOf: url)
                    viewModel.send(.uploadImage(image: fileData))
                } catch {
                    self.error = error
                    isPresentingError = true
                }
            }
        case let .failure(fileError):
            error = fileError
            isPresentingError = true
        }
    }

    // MARK: - Navigation Menu Content

    private func menuContent() -> some View {
        Group {
            Button(L10n.add, systemImage: "plus") {
                isImportingFile = true
            }
            Divider()
            Button(L10n.delete, systemImage: "trash", role: .destructive) {
                isPresentingDeletion = true
            }
        }
    }
}
