//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Engine
import JellyfinAPI
import SwiftUI

struct ItemImageDetailsView: View {

    @Router
    private var router

    @Environment(\.isEditing)
    private var isEditing

    @ObservedObject
    private var viewModel: ItemImagesViewModel

    private let imageSource: ImageSource

    private let index: Int?
    private let width: Int?
    private let height: Int?
    private let language: String?
    private let provider: String?
    private let rating: Double?
    private let ratingVotes: Int?

    private let onSave: (() -> Void)?
    private let onDelete: (() -> Void)?

    var body: some View {
        List {
            Section {
                ImageView(imageSource)
                    .placeholder { _ in
                        Image(systemName: "photo")
                    }
                    .failure {
                        Image(systemName: "photo")
                    }
                    .pipeline(.Swiftfin.other)
            }
            .scaledToFit()
            .frame(maxHeight: 300)
            .frame(maxWidth: .infinity)
            .listRowBackground(Color.clear)
            .listRowCornerRadius(0)
            .listRowInsets(.zero)

            Section(L10n.details) {
                if let provider {
                    LabeledContent(L10n.provider, value: provider)
                }

                if let language {
                    LabeledContent(L10n.language, value: language)
                }

                if let width, let height {
                    LabeledContent(
                        L10n.dimensions,
                        value: "\(width) x \(height)"
                    )
                }

                if let index {
                    LabeledContent(L10n.index, value: index.description)
                }
            }

            if let rating {
                Section(L10n.ratings) {
                    LabeledContent(L10n.rating, value: rating.formatted(.number.precision(.fractionLength(2))))

                    if let ratingVotes {
                        LabeledContent(L10n.votes, value: ratingVotes, format: .number)
                    }
                }
            }

            if let url = imageSource.url {
                Section {
                    ChevronButton(
                        L10n.imageSource,
                        external: true
                    ) {
                        UIApplication.shared.open(url)
                    }
                }
            }

            if isEditing, let onDelete {
                StateAdapter(initialValue: false) { isPresentingConfirmation in
                    Button(L10n.delete, role: .destructive) {
                        isPresentingConfirmation.wrappedValue = true
                    }
                    .buttonStyle(.primary)
                    .confirmationDialog(
                        L10n.delete,
                        isPresented: isPresentingConfirmation,
                        titleVisibility: .visible
                    ) {
                        Button(
                            L10n.delete,
                            role: .destructive,
                            action: onDelete
                        )

                        Button(L10n.cancel, role: .cancel) {
                            isPresentingConfirmation.wrappedValue = false
                        }
                    } message: {
                        Text(L10n.deleteItemConfirmationMessage)
                    }
                }
            }
        }
        .navigationTitle(L10n.image)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarCloseButton {
            router.dismiss()
        }
        .topBarTrailing {
            if viewModel.background.is(.updating) {
                ProgressView()
            }

            if !isEditing, let onSave {
                Button(L10n.save) {
                    onSave()
                }
                .buttonStyle(.toolbarPill)
            }
        }
        .onReceive(viewModel.events) { event in
            switch event {
            case .updated:
                UIDevice.feedback(.success)
                router.dismiss()
            }
        }
        .errorMessage($viewModel.error)
    }
}

extension ItemImageDetailsView {

    // Initialize as a Local Server Image

    init(
        viewModel: ItemImagesViewModel,
        imageInfo: ImageInfo
    ) {
        self.viewModel = viewModel
        self.imageSource = imageInfo.itemImageSource(
            itemID: viewModel.item.id!,
            client: viewModel.userSession.client
        )
        self.index = imageInfo.imageIndex
        self.width = imageInfo.width
        self.height = imageInfo.height
        self.language = nil
        self.provider = nil
        self.rating = nil
        self.ratingVotes = nil
        self.onSave = nil
        self.onDelete = {
            viewModel.deleteImage(imageInfo)
        }
    }

    // Initialize as a Remote Search Image

    init(
        viewModel: ItemImagesViewModel,
        remoteImageInfo: RemoteImageInfo
    ) {
        self.viewModel = viewModel
        self.imageSource = ImageSource(url: remoteImageInfo.url?.url)
        self.index = nil
        self.width = remoteImageInfo.width
        self.height = remoteImageInfo.height
        self.language = remoteImageInfo.language
        self.provider = remoteImageInfo.providerName
        self.rating = remoteImageInfo.communityRating
        self.ratingVotes = remoteImageInfo.voteCount
        self.onSave = {
            viewModel.setImage(remoteImageInfo)
        }
        self.onDelete = nil
    }
}
