//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

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
    private var isFilePickerPresented = false
    @State
    private var isPhotoPickerPresented = false
    @State
    private var selectedType: ImageType?
    @State
    private var error: Error?

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
        .navigationTitle(L10n.images)
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            viewModel.refresh()
        }
        .onFirstAppear {
            viewModel.refresh()
        }
        .navigationBarCloseButton {
            router.dismiss()
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
                   let file = UIImage(data: data),
                   let type = selectedType
                {
                    viewModel.imageType = type
                    viewModel.upload(file)
                    selectedType = nil
                }
            case let .failure(fileError):
                error = fileError
                selectedType = nil
            }
        }
        .photoPicker(
            isPresented: $isPhotoPickerPresented,
            viewModel: viewModel
        )
        .errorMessage($viewModel.error)
    }

    @ViewBuilder
    private var contentView: some View {
        ScrollView {
            ForEach(ImageType.allCases.sorted(using: \.rawValue), id: \.self) { imageType in
                Section {
                    imageScrollView(for: imageType)

                    RowDivider()
                        .padding(.vertical, 16)
                } header: {
                    sectionHeader(for: imageType)
                }
            }
        }
    }

    @ViewBuilder
    private func imageScrollView(for imageType: ImageType) -> some View {
        let images = viewModel.images[imageType] ?? []

        if images.isNotEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(images, id: \.self) { imageInfo in
                        imageButton(imageInfo: imageInfo) {
                            viewModel.imageType = imageInfo.imageType
                            router.route(
                                to: .itemImageDetails(
                                    viewModel: viewModel,
                                    imageDetail: imageInfo
                                )
                            )
                        }
                    }
                }
                .edgePadding(.horizontal)
            }
        }
    }

    @ViewBuilder
    private func sectionHeader(for imageType: ImageType) -> some View {
        HStack {
            Text(imageType.displayTitle)
                .font(.headline)

            Spacer()

            Menu(L10n.options, systemImage: "plus") {
                Button(L10n.search, systemImage: "magnifyingglass") {
                    router.route(to: .searchItemImages(viewModel: viewModel, imageType: imageType))
                }

                Divider()

                Button(L10n.uploadFile, systemImage: "document.badge.plus") {
                    selectedType = imageType
                    isFilePickerPresented = true
                }

                Button(L10n.uploadPhoto, systemImage: "photo.badge.plus") {
                    viewModel.imageType = imageType
                    isPhotoPickerPresented = true
                }
            }
            .font(.body)
            .labelStyle(.iconOnly)
            .fontWeight(.semibold)
            .foregroundStyle(accentColor)
        }
        .edgePadding(.horizontal)
    }

    @ViewBuilder
    private func imageButton(
        imageInfo: ImageInfo,
        onSelect: @escaping () -> Void
    ) -> some View {
        let posterType = imageInfo.imageType?.posterDisplayType(for: viewModel.item) ?? .landscape

        Button(action: onSelect) {
            ZStack {
                Color.secondarySystemFill

                ImageView(
                    imageInfo.itemImageSource(
                        itemID: viewModel.item.id!,
                        client: viewModel.userSession.client
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
            .frame(maxHeight: 150)
            .posterShadow()
        }
    }
}
