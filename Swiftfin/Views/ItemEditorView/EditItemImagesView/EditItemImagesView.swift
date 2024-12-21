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
    var viewModel: ItemViewModel

    // MARK: - Ordered Items

    private var orderedItems: [ImageType] {
        ImageType.allCases.sorted { (lhs: ImageType, rhs: ImageType) in
            if lhs == .primary && rhs != .primary {
                return true
            } else if lhs != .primary && rhs == .primary {
                return false
            } else {
                return lhs.rawValue.localizedCaseInsensitiveCompare(rhs.rawValue) == .orderedAscending
            }
        }
    }

    // MARK: - Body

    @ViewBuilder
    var body: some View {
        contentView
            .navigationBarTitle(L10n.replaceImages)
            .navigationBarTitleDisplayMode(.inline)
            .onFirstAppear {
                viewModel.send(.fetchAllImages)
            }
    }

    // MARK: - Content View

    private var contentView: some View {
        ScrollView {
            ForEach(orderedItems, id: \.self) { imageType in
                Section {
                    if let images = viewModel.imagesByType[imageType.rawValue] {
                        if images.count == 1 {
                            // Render the single image using the specified logic
                            singleImageButton(imageType, imageIndex: 0)
                        } else {
                            // Render multiple images in a horizontal scroll view
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(images.indices, id: \.self) { index in
                                        multipleImageButton(imageType, imageIndex: index)
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                    } else {
                        missingImageView(for: imageType)
                            .frame(height: 150)
                    }
                    Divider()
                        .padding(.vertical, 16)
                } header: {
                    HStack(alignment: .center) {
                        Text(imageType.rawValue.localizedCapitalized)
                        Spacer()
                    }
                    .font(.headline)
                    .padding(.horizontal, 16)
                }
            }
        }
    }

    // MARK: - Single Image Button View

    private func singleImageButton(_ imageType: ImageType, imageIndex: Int) -> some View {
        Button {
            router.route(
                to: \.imagePicker,
                RemoteItemImageViewModel(
                    item: viewModel.item,
                    imageType: imageType,
                    includeAllLanguages: false
                )
            )
        } label: {
            ZStack(alignment: .bottomTrailing) {
                Color.secondarySystemFill
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                ZStack {
                    RedrawOnNotificationView(.itemMetadataDidChange) {
                        ImageView(viewModel.item.imageSource(imageType))
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

                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Image(systemName: "pencil.circle.fill")
                                .resizable()
                                .frame(width: 30, height: 30)
                                .shadow(radius: 10)
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(accentColor.overlayColor, accentColor)
                                .padding(8)
                        }
                    }
                }
            }
            .scaledToFit()
            .posterStyle(.landscape)
            .frame(width: 150, height: 150)
            .cornerRadius(8)
            .shadow(radius: 4)
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Multiple Image Button View

    private func multipleImageButton(_ imageType: ImageType, imageIndex: Int) -> some View {
        Button {
            router.route(
                to: \.imagePicker,
                RemoteItemImageViewModel(
                    item: viewModel.item,
                    imageType: imageType,
                    includeAllLanguages: false,
                    imageIndex: imageIndex
                )
            )
        } label: {
            ZStack(alignment: .bottomTrailing) {
                if let image = viewModel.imagesByType[imageType.rawValue]?[imageIndex] {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150, height: 150)
                        .cornerRadius(8)
                        .shadow(radius: 4)
                } else {
                    Color.secondarySystemFill
                        .frame(width: 150, height: 150)
                        .cornerRadius(8)
                        .shadow(radius: 4)
                }

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image(systemName: "pencil.circle.fill")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .shadow(radius: 10)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(accentColor.overlayColor, accentColor)
                            .padding(8)
                    }
                }
            }
        }
    }

    // MARK: - Missing Image View

    private func missingImageView(for imageType: ImageType) -> some View {
        VStack {
            Image(systemName: "photo")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.secondary)
            Text(L10n.none)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}
