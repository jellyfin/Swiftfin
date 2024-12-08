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

    @Default(.accentColor)
    private var accentColor

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
            .navigationBarTitle("Images")
            .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Content View

    private var contentView: some View {
        ScrollView {
            ForEach(
                orderedItems,
                id: \.self
            ) { itemType in
                Section {
                    imageButton(itemType)
                    Divider()
                        .padding(.vertical, 16)
                } header: {
                    HStack(alignment: .center) {
                        Text(itemType.rawValue.localizedCapitalized)
                        Spacer()
                    }
                    .font(.headline)
                }
                .padding(
                    EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
                )
            }
        }
    }

    // MARK: - Image Button View

    private func imageButton(_ imageType: ImageType) -> some View {
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
        }
    }
}
