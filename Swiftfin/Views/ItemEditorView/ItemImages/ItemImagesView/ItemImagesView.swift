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

struct ItemImagesView: View {

    // MARK: - Defaults

    @Default(.accentColor)
    private var accentColor

    // MARK: - Observed & Environment Objects

    @EnvironmentObject
    private var router: ItemImagesCoordinator.Router

    @StateObject
    var viewModel: ItemImagesViewModel

    // MARK: - Dialog State

    @State
    private var selectedType: ImageType?

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
            .navigationBarCloseButton {
                router.dismissCoordinator()
            }
            .fileImporter(
                isPresented: .constant(selectedType != nil),
                allowedContentTypes: [.image],
                allowsMultipleSelection: false
            ) {
                switch $0 {
                case let .success(urls):
                    if let file = urls.first, let type = selectedType {
                        viewModel.send(.uploadImage(file: file, type: type))
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

        if imageArray.isNotEmpty {
            let sortedImageArray = imageArray.sorted { lhs, rhs in
                (lhs.key.imageIndex ?? 0) < (rhs.key.imageIndex ?? 0)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(sortedImageArray, id: \.key) { imageData in
                        imageButton(imageData.value) {
                            router.route(to: \.deleteImage, imageData)
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

    private func imageButton(_ image: UIImage, onSelect: @escaping () -> Void) -> some View {
        Button(action: onSelect) {
            ZStack {
                Color.secondarySystemFill
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            }
            .scaledToFit()
            .posterStyle(image.size.height > image.size.width ? .portrait : .landscape)
            .frame(maxHeight: 150)
            .shadow(radius: 4)
            .padding(16)
        }
    }
}
