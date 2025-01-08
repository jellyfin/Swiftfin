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
import Factory
import JellyfinAPI
import SwiftUI

struct ItemImagesView: View {

    // MARK: - Defaults

    @Default(.accentColor)
    private var accentColor

    // MARK: - User Session

    @Injected(\.currentUserSession)
    private var userSession

    // MARK: - Observed & Environment Objects

    @EnvironmentObject
    private var router: ItemImagesCoordinator.Router

    @StateObject
    var viewModel: ItemImagesViewModel

    // MARK: - Dialog State

    @State
    private var selectedImage: ImageInfo?
    @State
    private var selectedType: ImageType?
    @State
    private var isFilePickerPresented = false

    // MARK: - Error State

    @State
    private var error: Error?

    // MARK: - Body

    var body: some View {
        ZStack {
            switch viewModel.state {
            case .content, .deleting, .updating:
                imageView
            case .initial:
                DelayedProgressView()
            case let .error(error):
                ErrorView(error: error)
                    .onRetry {
                        viewModel.send(.refresh)
                    }
            }
        }
        .navigationTitle(L10n.images)
        .navigationBarTitleDisplayMode(.inline)
        .onFirstAppear {
            viewModel.send(.refresh)
        }
        .navigationBarCloseButton {
            router.dismissCoordinator()
        }
        .sheet(item: $selectedImage) {
            selectedImage = nil
        } content: { imageInfo in
            ItemImageDetailsView(
                viewModel: viewModel,
                imageSource: imageInfo.itemImageSource(
                    itemID: viewModel.item.id!,
                    client: viewModel.userSession.client
                ),
                index: imageInfo.imageIndex,
                width: imageInfo.width,
                height: imageInfo.height,
                onClose: {
                    selectedImage = nil
                },
                onDelete: {
                    viewModel.send(.deleteImage(imageInfo))
                    selectedImage = nil
                }
            )
            .navigationTitle(imageInfo.imageType?.displayTitle ?? "")
            .environment(\.isEditing, true)
        }
        .fileImporter(
            isPresented: $isFilePickerPresented,
            allowedContentTypes: [.png, .jpeg, .heic],
            allowsMultipleSelection: false
        ) {
            switch $0 {
            case let .success(urls):
                if let file = urls.first, let type = selectedType {
                    viewModel.send(.uploadImage(file: file, type: type))
                    selectedType = nil
                }
            case let .failure(fileError):
                error = fileError
                selectedType = nil
            }
        }
        .onReceive(viewModel.events) { event in
            switch event {
            case .updated, .deleted: ()
            case let .error(eventError):
                self.error = eventError
            }
        }
        .errorMessage($error)
    }

    // MARK: - Image View

    @ViewBuilder
    private var imageView: some View {
        ScrollView {
            ForEach(ImageType.allCases.sorted(using: \.rawValue), id: \.self) { imageType in
                Section {
                    imageScrollView(for: imageType)

                    Divider()
                        .padding(.vertical, 16)
                } header: {
                    sectionHeader(for: imageType)
                }
            }
        }
    }

    // MARK: - Image Scroll View

    @ViewBuilder
    private func imageScrollView(for imageType: ImageType) -> some View {
        let imageArray = viewModel.images.filter { $0.imageType == imageType }

        if imageArray.isNotEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(imageArray, id: \.self) { imageInfo in
                        imageButton(imageInfo: imageInfo) {
                            selectedImage = imageInfo
                        }
                    }
                }
            }
        }
    }

    // MARK: - Section Header

    @ViewBuilder
    private func sectionHeader(for imageType: ImageType) -> some View {
        HStack(alignment: .center, spacing: 16) {
            Text(imageType.rawValue.localizedCapitalized)
                .font(.headline)

            Spacer()

            Menu(L10n.options, systemImage: "plus") {
                Button(L10n.search, systemImage: "magnifyingglass") {
                    router.route(
                        to: \.addImage,
                        imageType
                    )
                }

                Divider()

                Button(L10n.uploadFile, systemImage: "document.badge.plus") {
                    selectedType = imageType
                    isFilePickerPresented = true
                }

                Button(L10n.uploadPhoto, systemImage: "photo.badge.plus") {
                    router.route(to: \.photoPicker, imageType)
                }
            }
            .font(.body)
            .labelStyle(.iconOnly)
            .backport
            .fontWeight(.semibold)
            .foregroundStyle(accentColor)
        }
        .padding(.horizontal, 30)
    }

    // MARK: - Image Button

    @ViewBuilder
    private func imageButton(
        imageInfo: ImageInfo,
        onSelect: @escaping () -> Void
    ) -> some View {
        Button(action: onSelect) {
            ZStack {
                Color.secondarySystemFill

                ImageView(
                    imageInfo.itemImageSource(
                        itemID: viewModel.item.id!,
                        client: userSession!.client
                    )
                )
                .placeholder { _ in
                    Image(systemName: "circle")
                }
                .failure {
                    Image(systemName: "questionmark")
                }
                .scaledToFit()
                .frame(maxWidth: .infinity)
            }
            .scaledToFit()
            .posterStyle(imageInfo.height ?? 0 > imageInfo.width ?? 0 ? .portrait : .landscape)
            .frame(maxHeight: 150)
            .shadow(radius: 4)
            .padding(16)
        }
    }
}
