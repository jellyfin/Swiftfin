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

struct EditItemImagesView: View {

    // MARK: - Defaults

    @Default(.accentColor)
    private var accentColor

    // MARK: - Observed & Environment Objects

    @EnvironmentObject
    private var router: ItemEditorCoordinator.Router

    @ObservedObject
    var viewModel: ItemImagesViewModel

    // MARK: - Dialog State

    @State
    private var isImportingImage = false
    @State
    private var isDeletingImage = false

    @State
    private var selectedImage: LocalImageInfo?

    // MARK: - Error State

    @State
    private var error: Error?

    // MARK: - Computed Properties

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
            .navigationBarTitle(L10n.replaceImages)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { viewModel.send(.refresh) }
            .sheet(item: $selectedImage) { item in
                deletionSheet(
                    item.image!,
                    type: item.type!,
                    index: item.index ?? 0
                )
            }
            .fileImporter(
                isPresented: $isImportingImage,
                allowedContentTypes: [.image],
                allowsMultipleSelection: false
            ) {
                handleFileImport(result: $0)
            }
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

    // MARK: - Helpers

    @ViewBuilder
    private func imageScrollView(for imageType: ImageType) -> some View {
        if let images = viewModel.localImages[imageType.rawValue] {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(images, id: \.self) { image in
                        imageButton(image) {
                            selectedImage = LocalImageInfo(
                                index: 0,
                                image: image,
                                type: imageType
                            )
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    @ViewBuilder
    private func sectionHeader(for imageType: ImageType) -> some View {
        HStack(alignment: .center, spacing: 16) {
            Text(imageType.rawValue.localizedCapitalized)
            Spacer()
            Button(action: { viewModel.send(.setImageType(imageType))
                router.route(to: \.addImage, viewModel)
            }) {
                Image(systemName: "magnifyingglass")
            }
            Button(action: { isImportingImage = true }) {
                Image(systemName: "plus")
            }
        }
        .font(.headline)
        .padding(.horizontal, 16)
    }

    private func imageButton(_ image: UIImage, onSelect: @escaping () -> Void) -> some View {
        Button(action: onSelect) {
            ZStack {
                Color.secondarySystemFill
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            }
            .posterStyle(.landscape)
            .frame(maxHeight: 150)
            .shadow(radius: 4)
            .padding(16)
        }
    }

    private func handleFileImport(result: Result<[URL], Error>) {
        switch result {
        case let .success(urls):
            if let url = urls.first {
                do {
                    let data = try Data(contentsOf: url)
                    if let image = UIImage(data: data) {
                        viewModel.send(.uploadImage(image: image))
                    }
                } catch {
                    print("Error loading image data: \(error.localizedDescription)")
                }
            }
        case let .failure(fileError):
            error = fileError
            print("File import error: \(fileError.localizedDescription)")
        }
    }

    // MARK: - Delete Image Confirmation

    @ViewBuilder
    private func deletionSheet(_ image: UIImage, type: ImageType, index: Int) -> some View {
        NavigationView {
            VStack {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()

                Text("\(Int(image.size.width)) x \(Int(image.size.height))")
                    .font(.body)

                Text(image.accessibilityIdentifier ?? "-")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .navigationTitle(L10n.replaceImages)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarCloseButton {
                selectedImage = nil
            }
            .topBarTrailing {
                Button(L10n.delete, role: .destructive) {
                    viewModel.send(.setImageType(type))
                    viewModel.send(.deleteImage(index: index))
                    viewModel.send(.setImageType(nil))
                    selectedImage = nil
                }
                .buttonStyle(.toolbarPill(.red))
            }
        }
    }
}
