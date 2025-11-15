//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

struct ItemImagesView: View {

    // MARK: - Defaults

    @Default(.accentColor)
    private var accentColor

    // MARK: - Observed & Environment Objects

    @Router
    private var router

    @StateObject
    var viewModel: ItemImagesViewModel

    // MARK: - Dialog State

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
            case .content:
                imageView
            case .initial:
                ProgressView()
            case let .error(error):
                ErrorView(error: error)
            }
        }
        .navigationTitle(L10n.images)
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            viewModel.send(.refresh)
        }
        .onFirstAppear {
            viewModel.send(.refresh)
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
                if let file = urls.first, let type = selectedType {
                    viewModel.send(.uploadFile(file: file, type: type))
                    selectedType = nil
                }
            case let .failure(fileError):
                error = fileError
                selectedType = nil
            }
        }
        .onReceive(viewModel.events) { event in
            switch event {
            case .updated: ()
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

                    RowDivider()
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
        let images = viewModel.images[imageType] ?? []

        if images.isNotEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(images, id: \.self) { imageInfo in
                        imageButton(imageInfo: imageInfo) {
                            router.route(
                                to: .itemImageDetails(
                                    viewModel: viewModel,
                                    imageInfo: imageInfo
                                )
                            )
                        }
                    }
                }
                .edgePadding(.horizontal)
            }
        }
    }

    // MARK: - Section Header

    @ViewBuilder
    private func sectionHeader(for imageType: ImageType) -> some View {
        HStack {
            Text(imageType.displayTitle)
                .font(.headline)

            Spacer()

            Menu(L10n.options, systemImage: "plus") {
                Button(L10n.search, systemImage: "magnifyingglass") {
                    router.route(to: .addItemImage(viewModel: viewModel, imageType: imageType))
                }

                Divider()

                Button(L10n.uploadFile, systemImage: "document.badge.plus") {
                    selectedType = imageType
                    isFilePickerPresented = true
                }

                Button(L10n.uploadPhoto, systemImage: "photo.badge.plus") {
                    router.route(to: .itemImageSelector(viewModel: viewModel, imageType: imageType))
                }
            }
            .font(.body)
            .labelStyle(.iconOnly)
            .fontWeight(.semibold)
            .foregroundStyle(accentColor)
        }
        .edgePadding(.horizontal)
    }

    // MARK: - Image Button

    // TODO: instead of using `posterStyle`, should be sized based on
    //       the image type and just ignore and poster styling
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
            .posterStyle(imageInfo.height ?? 0 > imageInfo.width ?? 0 ? .portrait : .landscape)
            .frame(maxHeight: 150)
            .posterShadow()
        }
    }
}
