//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct ItemImageDetailsView: View {

    @Environment(\.isEditing)
    private var isEditing

    // MARK: - State, Observed, & Environment Objects

    @EnvironmentObject
    private var router: BasicNavigationViewCoordinator.Router

    @ObservedObject
    private var viewModel: ItemImagesViewModel

    // MARK: - Image Variable

    private let imageSource: ImageSource

    // MARK: - Description Variables

    private let index: Int?
    private let width: Int?
    private let height: Int?
    private let language: String?
    private let provider: String?
    private let rating: Double?
    private let ratingVotes: Int?

    // MARK: - Image Actions

    private let onClose: () -> Void
    private let onSave: (() -> Void)?
    private let onDelete: (() -> Void)?

    // MARK: - Initializer

    init(
        viewModel: ItemImagesViewModel,
        imageSource: ImageSource,
        index: Int? = nil,
        width: Int? = nil,
        height: Int? = nil,
        language: String? = nil,
        provider: String? = nil,
        rating: Double? = nil,
        ratingVotes: Int? = nil,
        onClose: @escaping () -> Void,
        onSave: (() -> Void)? = nil,
        onDelete: (() -> Void)? = nil
    ) {
        self.viewModel = viewModel
        self.imageSource = imageSource
        self.index = index
        self.width = width
        self.height = height
        self.language = language
        self.provider = provider
        self.rating = rating
        self.ratingVotes = ratingVotes
        self.onClose = onClose
        self.onSave = onSave
        self.onDelete = onDelete
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            contentView
                .navigationTitle(L10n.image)
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarCloseButton {
                    onClose()
                }
                .topBarTrailing {
                    if viewModel.backgroundStates.contains(.updating) {
                        ProgressView()
                    }

                    if let onSave {
                        Button(L10n.save, action: onSave)
                            .buttonStyle(.toolbarPill)
                    }
                }
        }
    }

    // MARK: - Content View

    @ViewBuilder
    private var contentView: some View {
        List {
            HeaderSection(
                imageSource: imageSource,
                posterType: height ?? 0 > width ?? 0 ? .portrait : .landscape
            )

            DetailsSection(
                url: imageSource.url,
                index: index,
                language: language,
                width: width,
                height: height,
                provider: provider,
                rating: rating,
                ratingVotes: ratingVotes
            )

            if isEditing, let onDelete {
                DeleteButton {
                    onDelete()
                }
            }
        }
    }
}
