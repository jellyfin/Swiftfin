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

struct EditItemImagesView: View {

    // MARK: - Defaults

    @Default(.accentColor)
    private var accentColor

    // MARK: - Observed & Environment Objects

    @EnvironmentObject
    private var router: ItemEditorCoordinator.Router

    @StateObject
    var viewModel: ItemImagesViewModel

    // MARK: - Dialog State

    @State
    private var selectedImage: ImageInfo?
    @State
    private var uploadType: ImageType?

    // MARK: - Error State

    @State
    private var error: Error?

    // MARK: - Ordered ImageTypes

    private var orderedItems: [ImageType] {
        ImageType.allCases.sorted { lhs, rhs in
            if lhs == .primary { return true }
            if rhs == .primary { return false }
            return lhs.rawValue.localizedCaseInsensitiveCompare(rhs.rawValue) == .orderedAscending
        }
    }

    // MARK: - Body

    var body: some View {
        contentView
            .navigationBarTitle(L10n.images)
            .navigationBarTitleDisplayMode(.inline)
            .onFirstAppear {
                viewModel.send(.refresh)
            }
            .sheet(item: $selectedImage) { imageInfo in
                deletionSheet(imageInfo)
            }
            .fileImporter(
                isPresented: .constant(uploadType != nil),
                allowedContentTypes: [.image],
                allowsMultipleSelection: false
            ) {
                switch $0 {
                case let .success(urls):
                    if let url = urls.first {
                        do {
                            if let uploadType {
                                viewModel.send(.uploadImage(url: url, type: uploadType))
                            }
                            uploadType = nil
                        }
                    }
                case let .failure(fileError):
                    self.error = fileError
                }
            }
            .onReceive(viewModel.events) { event in
                switch event {
                case .updated:
                    viewModel.send(.refresh)
                case .deleted:
                    break
                case let .error(eventError):
                    self.error = eventError
                }
            }
            .errorMessage($error)
    }

    // MARK: - Content View

    private var contentView: some View {
        ScrollView {
            ForEach(orderedItems, id: \.self) { imageType in
                Section {
                    imageScrollView(for: imageType)
                    Divider().padding(.vertical, 16)
                } header: {
                    sectionHeader(for: imageType)
                }
            }
        }
    }

    // MARK: - Image Scrolle View

    @ViewBuilder
    private func imageScrollView(for imageType: ImageType) -> some View {
        let filteredImages = viewModel.images.filter { $0.key.imageType == imageType }
        let imageArray = Array(filteredImages)

        if !imageArray.isEmpty {
            let sortedImageArray = imageArray.sorted { lhs, rhs in
                (lhs.key.imageIndex ?? 0) < (rhs.key.imageIndex ?? 0)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(sortedImageArray, id: \.key) { imageData in
                        imageButton(imageData.value) {
                            selectedImage = imageData.key
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
                Button(action: {
                    router.route(
                        to: \.addImage,
                        RemoteImageInfoViewModel(
                            item: viewModel.item,
                            imageType: imageType
                        )
                    )
                }) {
                    Label(L10n.search, systemImage: "magnifyingglass")
                }

                Divider()

                Button(action: {
                    uploadType = imageType
                }) {
                    Label(L10n.uploadFile, systemImage: "document.badge.plus")
                }

                Button(action: {
                    uploadType = imageType
                }) {
                    Label(L10n.uploadPhoto, systemImage: "photo.badge.plus")
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

    private func imageButton(_ image: UIImage, onSelect: @escaping () -> Void) -> some View {
        Button(action: onSelect) {
            ZStack {
                Color.secondarySystemFill
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            }
            .posterStyle(image.size.height > image.size.width ? .portrait : .landscape)
            .frame(maxHeight: 150)
            .shadow(radius: 4)
            .padding(16)
        }
    }

    // MARK: - Delete Image Confirmation Sheet

    @ViewBuilder
    private func deletionSheet(_ imageInfo: ImageInfo) -> some View {
        if let image = viewModel.images[imageInfo] {
            NavigationView {
                VStack {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()

                    Text("\(Int(image.size.width)) x \(Int(image.size.height))")
                        .font(.headline)
                }
                .padding(.horizontal)
                .navigationTitle(L10n.deleteImage)
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarCloseButton {
                    selectedImage = nil
                }
                .topBarTrailing {
                    Button(L10n.delete, role: .destructive) {
                        viewModel.send(.deleteImage(imageInfo))
                        selectedImage = nil
                    }
                    .buttonStyle(.toolbarPill(.red))
                }
            }
        } else {
            ErrorView(error: JellyfinAPIError(L10n.unknownError))
        }
    }
}
