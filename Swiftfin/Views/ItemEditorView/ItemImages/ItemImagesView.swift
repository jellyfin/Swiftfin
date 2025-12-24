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
            SeparatorVStack(alignment: .leading) {
                Divider()
                    .edgePadding(.horizontal)
                    .padding(.vertical, 10)
            } content: {
                ForEach(
                    ImageType.allCases.sorted(using: \.rawValue),
                    id: \.self
                ) { imageType in
                    imageSection(for: imageType)
                }
            }
        }
    }

    // MARK: - Image Scroll View

    @ViewBuilder
    private func imageSection(for imageType: ImageType) -> some View {
        let images = viewModel.images[imageType] ?? []

        PosterHStack(
            elements: images,
            type: images.first?.preferredPosterDisplayType ?? .portrait
        ) { imageInfo, _ in
            router.route(
                to: .itemImageDetails(
                    viewModel: viewModel,
                    imageInfo: imageInfo
                )
            )
        } header: {
            sectionHeader(for: imageType)
        }
        .customEnvironment(
            for: ImageInfo.self,
            value: .init(
                itemID: viewModel.item.id!,
                client: viewModel.userSession.client
            )
        )
    }

    // MARK: - Section Header

    @ViewBuilder
    private func sectionHeader(for imageType: ImageType) -> some View {
        HStack {
            Text(imageType.displayTitle)
                .accessibilityAddTraits(.isHeader)

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
            .labelStyle(.iconOnly)
            .foregroundStyle(accentColor)
        }
        .font(.title2)
        .fontWeight(.semibold)
        .edgePadding(.horizontal)
    }

    // MARK: - Image Button

    @ViewBuilder
    private func imageButton(
        imageInfo: ImageInfo,
        onSelect: @escaping () -> Void
    ) -> some View {
        Button(action: onSelect) {
            PosterImage(
                item: imageInfo,
                type: imageInfo.preferredPosterDisplayType
            )
            .pipeline(.Swiftfin.other)
            .posterShadow()
            .customEnvironment(
                for: ImageInfo.self,
                value: .init(itemID: viewModel.item.id!, client: viewModel.userSession.client)
            )
        }
    }
}
