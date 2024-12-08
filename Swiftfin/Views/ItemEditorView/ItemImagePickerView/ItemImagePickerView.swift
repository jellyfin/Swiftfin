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

    @Default(.accentColor)
    private var accentColor

    @EnvironmentObject
    private var router: BasicNavigationViewCoordinator.Router

    @ObservedObject
    private var viewModel: RemoteItemImageViewModel

    @State
    private var isPresentingConfirmation: Bool = false
    @State
    private var isPresentingDeletion: Bool = false
    @State
    private var isImportingFile: Bool = false

    @State
    private var selectedImage: RemoteImageInfo? {
        didSet {
            if selectedImage != nil {
                isPresentingConfirmation = true
            } else {
                isPresentingConfirmation = false
            }
        }
    }

    init(viewModel: RemoteItemImageViewModel) {
        self.viewModel = viewModel
    }

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
                Button(L10n.add, systemImage: "plus") {
                    isImportingFile = true
                }

                Divider()

                Button(L10n.delete, systemImage: "trash", role: .destructive) {
                    isPresentingDeletion = true
                }
            }
            .fileImporter(
                isPresented: $isImportingFile,
                allowedContentTypes: [.image],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case let .success(urls):
                    if let url = urls.first {
                        guard url.startAccessingSecurityScopedResource() else {
                            return
                        }
                        defer { url.stopAccessingSecurityScopedResource() }

                        if let imageData = try? Data(contentsOf: url) {
                            viewModel.send(.setImage(imageData: imageData))
                            router.dismissCoordinator()
                        }
                    }
                case .failure:
                    break
                }
            }
            .confirmationDialog(
                L10n.save,
                isPresented: $isPresentingConfirmation,
                titleVisibility: .visible
            ) {
                Button(L10n.confirm) {
                    if let newImageURL = selectedImage?.url {
                        viewModel.send(.setImage(imageURL: newImageURL))
                    }
                    selectedImage = nil
                    router.dismissCoordinator()
                }
                Button(L10n.cancel, role: .cancel) {
                    selectedImage = nil
                }
            }
            .confirmationDialog(
                L10n.delete,
                isPresented: $isPresentingDeletion,
                titleVisibility: .visible
            ) {
                Button(L10n.delete, role: .destructive) {
                    viewModel.send(.deleteImage)
                    isPresentingDeletion = false
                    router.dismissCoordinator()
                }
                Button(L10n.cancel, role: .cancel) {
                    isPresentingDeletion = false
                }
            }
    }

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

    @ViewBuilder
    private var gridView: some View {
        if viewModel.images.isEmpty {
            Text(L10n.none)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .listRowSeparator(.hidden)
                .listRowInsets(.zero)
        } else {
            CollectionVGrid(
                viewModel.images,
                layout: .minWidth(150)
            ) { image in
                imageButton(image)
                    .padding(.vertical, 4)
            }
            .onReachedBottomEdge(offset: .offset(300)) {
                viewModel.send(.getNextPage)
            }
        }
    }

    private func imageButton(_ image: RemoteImageInfo?) -> some View {
        Button {
            selectedImage = image
        } label: {
            VStack {
                posterImage(image)

                if let imageWidth = image?.width, let imageHeight = image?.height {
                    Text("\(imageWidth) x \(imageHeight)")
                        .font(.body)
                }

                Text(image?.providerName ?? .emptyDash)
                    .font(.caption)
            }
            .foregroundStyle(Color.secondary)
        }
    }

    private func posterImage(_ posterImageInfo: RemoteImageInfo?) -> some View {
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
        .posterStyle(.landscape)
    }
}
