//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import CollectionHStack
import Defaults
import JellyfinAPI
import SwiftUI

struct ItemImagesView: View {

    @ObservedObject
    var viewModel: ItemImageViewModel

    @Router
    private var router

    @State
    private var isFilePickerPresented = false
    @State
    private var isPhotoPickerPresented = false
    @State
    private var selectedType: ImageType = .primary
    @State
    private var uploadError: Error?

    private var columns: CGFloat {
        posterType == .landscape ? 1.5 : 3
    }

    private var posterType: PosterDisplayType {
        selectedType.posterDisplayType(for: viewModel.item.type)
    }

    private var selectedImages: [ImageInfo] {
        viewModel.images[selectedType] ?? []
    }

    var body: some View {
        ZStack {
            switch viewModel.state {
            case .initial:
                ProgressView()
            case .content:
                contentView
            case .error:
                viewModel.error.map {
                    ErrorView(error: $0)
                }
            }
        }
        .backport
        .toolbarTitleDisplayMode(.inline)
        .navigationTitle(L10n.images)
        .navigationBarCloseButton {
            router.dismiss()
        }
        .onFirstAppear {
            viewModel.refresh()
        }
        .navigationBarMenuButton(
            isLoading: viewModel.background.is(.updating) || viewModel.background.is(.deleting),
            isHidden: selectedImages.isEmpty
        ) {
            addImageMenu
        }
        .fileImporter(
            isPresented: $isFilePickerPresented,
            allowedContentTypes: [.png, .jpeg, .heic],
            allowsMultipleSelection: false
        ) {
            switch $0 {
            case let .success(urls):
                if let url = urls.first {
                    viewModel.uploadFile(file: url, type: selectedType)
                }
            case let .failure(fileError):
                uploadError = fileError
            }
        }
        .photoPicker(
            isPresented: $isPhotoPickerPresented,
            isSaving: viewModel.background.is(.updating)
        ) {
            viewModel.uploadImage(image: $0, type: selectedType)
        }
        .onReceive(viewModel.events) { event in
            switch event {
            case .deleted:
                UIDevice.feedback(.success)
            case .updated:
                UIDevice.feedback(.success)
                isPhotoPickerPresented = false
            }
        }
        .errorMessage($uploadError)
    }

    @ViewBuilder
    private var contentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                InsetGroupedListHeader(
                    L10n.images,
                    description: L10n.imagesDescription
                )
                .edgePadding(.horizontal)
                .frame(maxWidth: .infinity)
                .padding(.top, 24)

                typePicker
                    .edgePadding(.horizontal)

                imagesView

                Divider()
                    .edgePadding(.horizontal)

                Text(selectedType.description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .edgePadding(.horizontal)
            }
        }
    }

    @ViewBuilder
    private var imagesView: some View {
        if selectedImages.isNotEmpty {
            CollectionHStack(
                uniqueElements: selectedImages,
                columns: columns
            ) { imageInfo in
                imageButton(imageInfo: imageInfo)
            }
            .clipsToBounds(false)
            .scrollBehavior(.continuousLeadingEdge)
            .insets(horizontal: EdgeInsets.edgePadding)
            .itemSpacing(EdgeInsets.edgePadding / 2)
            .id(selectedType)
            .transition(.opacity.animation(.linear(duration: 0.1)))
        } else {
            CollectionHStack(
                count: 1,
                columns: columns
            ) { _ in
                addImageButton
            }
            .insets(horizontal: EdgeInsets.edgePadding)
            .itemSpacing(EdgeInsets.edgePadding / 2)
            .scrollDisabled(true)
            .id(selectedType)
            .transition(.opacity.animation(.linear(duration: 0.1)))
        }
    }

    @ViewBuilder
    private var typePicker: some View {
        Menu {
            ForEach(ImageType.allCases.sorted(using: \.rawValue), id: \.self) { imageType in
                Button {
                    selectedType = imageType
                } label: {
                    if imageType == selectedType {
                        Label(imageType.displayTitle, systemImage: "checkmark")
                    } else {
                        Text(imageType.displayTitle)
                    }
                }
            }
        } label: {
            Label(
                selectedType.displayTitle,
                systemImage: "chevron.down"
            )
            .labelStyle(
                CapsuleLabelStyle(
                    isIconTrailing: true
                )
            )
            .font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var addImageMenu: some View {
        Button(L10n.search, systemImage: "magnifyingglass") {
            router.route(to: .remoteImageSearch(viewModel: viewModel, imageType: selectedType))
        }

        Divider()

        Button(L10n.uploadFile, systemImage: "document.badge.plus") {
            isFilePickerPresented = true
        }

        Button(L10n.uploadPhoto, systemImage: "photo.badge.plus") {
            isPhotoPickerPresented = true
        }
    }

    @ViewBuilder
    private func imageButton(imageInfo: ImageInfo) -> some View {
        if let userSession = viewModel.userSession {
            Button {
                router.route(to: .itemImageDetail(viewModel: viewModel, imageInfo: imageInfo))
            } label: {
                ZStack {
                    Color.secondarySystemFill

                    ImageView(
                        imageInfo.itemImageSource(
                            itemID: viewModel.item.id!,
                            client: userSession.client
                        )
                    )
                    .placeholder { _ in
                        Image(systemName: "photo")
                    }
                    .failure {
                        Image(systemName: "photo")
                    }
                    .pipeline(.Swiftfin.other)
                }
                .posterStyle(posterType)
                .subtleShadow()
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var addImageButton: some View {
        Menu {
            addImageMenu
        } label: {
            ZStack {
                Color.secondarySystemFill

                VStack {
                    Image(systemName: "photo.badge.plus")
                        .font(.title)
                    Text(L10n.add)
                        .font(.body)
                }
            }
            .posterStyle(posterType)
            .subtleShadow()
        }
        .buttonStyle(.plain)
    }
}
