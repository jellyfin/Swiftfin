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

    @Default(.accentColor)
    private var accentColor

    @Router
    private var router

    @ObservedObject
    var viewModel: ItemImageViewModel

    @State
    private var selectedType: ImageType = .primary

    @State
    private var deleteImageInfo: ImageInfo?
    @State
    private var isFilePickerPresented = false
    @State
    private var isPhotoPickerPresented = false
    @State
    private var uploadError: Error?

    private var selectedImages: [ImageInfo] {
        viewModel.images[selectedType] ?? []
    }

    private var posterType: PosterDisplayType {
        selectedType.posterDisplayType(for: viewModel.item.type)
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
        .refreshable {
            viewModel.refresh()
        }
        .onFirstAppear {
            viewModel.refresh()
        }
        .navigationBarCloseButton {
            router.dismiss()
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
                if let url = urls.first,
                   let data = try? Data(contentsOf: url),
                   let file = UIImage(data: data)
                {
                    viewModel.upload(file)
                }
            case let .failure(fileError):
                uploadError = fileError
            }
        }
        .photoPicker(
            isPresented: $isPhotoPickerPresented,
            viewModel: viewModel
        )
        .errorMessage($uploadError)
        .errorMessage($viewModel.error)
        .confirmationDialog(
            L10n.delete,
            isPresented: Binding<Bool>(
                get: { deleteImageInfo != nil },
                set: { if !$0 { deleteImageInfo = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button(L10n.delete, role: .destructive) {
                if let deleteImageInfo {
                    viewModel.deleteImageInfo = deleteImageInfo
                    viewModel.delete()
                }
            }

            Button(L10n.cancel, role: .cancel) {
                deleteImageInfo = nil
            }
        } message: {
            Text(L10n.deleteItemConfirmationMessage)
        }
        .onReceive(viewModel.events) { event in
            switch event {
            case .deleted:
                UIDevice.feedback(.success)
            case .updated:
                break
            }
        }
    }

    @ViewBuilder
    private var contentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                InsetGroupedListHeader(
                    L10n.images,
                    description: L10n.imagesDescription
                ) {
                    UIApplication.shared.open(.jellyfinDocsImages)
                }
                .frame(maxWidth: .infinity)
                .edgePadding(.horizontal)
                .padding(.top, 24)

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
                    .labelStyle(.episodeSelector)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .edgePadding(.horizontal)

                imageCarousel

                Divider()
                    .edgePadding(.horizontal)

                imageTypeDescription
                    .edgePadding(.horizontal)
            }
        }
    }

    private var columns: CGFloat {
        UIDevice.isPhone ? (posterType == .landscape ? 1.5 : 3) : 3.5
    }

    @ViewBuilder
    private var imageCarousel: some View {
        if selectedImages.isNotEmpty {
            CollectionHStack(
                uniqueElements: selectedImages,
                columns: columns
            ) { imageInfo in
                imageButton(imageInfo: imageInfo) {
                    deleteImageInfo = imageInfo
                }
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
    private var addImageMenu: some View {
        Button(L10n.search, systemImage: "magnifyingglass") {
            router.route(to: .remoteImageSearch(viewModel: viewModel, imageType: selectedType))
        }

        Divider()

        Button(L10n.uploadFile, systemImage: "document.badge.plus") {
            viewModel.imageType = selectedType
            isFilePickerPresented = true
        }

        Button(L10n.uploadPhoto, systemImage: "photo.badge.plus") {
            viewModel.imageType = selectedType
            isPhotoPickerPresented = true
        }
    }

    @ViewBuilder
    private var imageTypeDescription: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(selectedType.description)

            if !selectedType.isUsed {
                Text("This type is not used in official Jellyfin Clients.")
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            }
        }
        .font(.body)
        .transition(.opacity.animation(.linear(duration: 0.1)))
    }

    @ViewBuilder
    private func imageButton(
        imageInfo: ImageInfo,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            ZStack {
                Color.secondarySystemFill

                ImageView(
                    imageInfo.imageSource(item: viewModel.item)
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
            .posterShadow()
        }
    }

    private var addImageButton: some View {
        Menu {
            addImageMenu
        } label: {
            ZStack {
                Color.secondarySystemFill
                    .opacity(0.75)

                VStack {
                    Image(systemName: "photo.badge.plus")
                        .font(.title)
                        .foregroundStyle(Color.primary)

                    Text(L10n.add)
                        .font(.callout)
                        .foregroundStyle(Color.secondary)
                }
            }
            .posterStyle(posterType)
            .posterShadow()
        }
        .buttonStyle(.plain)
    }
}
