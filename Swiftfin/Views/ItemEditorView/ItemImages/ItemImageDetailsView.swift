//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct ItemImageDetailsView: View {

    @Router
    private var router

    @Environment(\.isEditing)
    private var isEditing

    @ObservedObject
    private var viewModel: ItemImageViewModel

    @State
    private var isPresentingDeleteConfirmation = false

    private let imageDetail: any ItemImageDetail
    private let imageSource: ImageSource

    init(
        viewModel: ItemImageViewModel,
        imageDetail: any ItemImageDetail
    ) {
        self.viewModel = viewModel
        self.imageDetail = imageDetail
        self.imageSource = imageDetail.imageSource(item: viewModel.item)
    }

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
                if let provider = imageDetail.provider {
                    LabeledContent(L10n.provider, value: provider)
                }

                if let language = imageDetail.language {
                    LabeledContent(L10n.language, value: language)
                }

                if let width = imageDetail.width, let height = imageDetail.height {
                    LabeledContent(
                        L10n.dimensions,
                        value: "\(width) x \(height)"
                    )
                }

                if let index = imageDetail.index {
                    LabeledContent(L10n.index, value: index.description)
                }
            }

            if let rating = imageDetail.rating {
                Section(L10n.ratings) {
                    LabeledContent(L10n.rating, value: rating.formatted(.number.precision(.fractionLength(2))))

                    if let ratingVotes = imageDetail.ratingVotes {
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

            if isEditing {
                Button(L10n.delete, role: .destructive) {
                    isPresentingDeleteConfirmation = true
                }
                .buttonStyle(.primary)
                .confirmationDialog(
                    L10n.delete,
                    isPresented: $isPresentingDeleteConfirmation,
                    titleVisibility: .visible
                ) {
                    Button(L10n.delete, role: .destructive) {
                        if let imageInfo = imageDetail as? ImageInfo {
                            viewModel.deleteImageInfo = imageInfo
                        }
                        viewModel.delete()
                    }

                    Button(L10n.cancel, role: .cancel) {}
                } message: {
                    Text(L10n.deleteItemConfirmationMessage)
                }
            }
        }
        .backport
        .toolbarTitleDisplayMode(.inline)
        .navigationTitle(L10n.image)
        .navigationBarCloseButton {
            router.dismiss()
        }
        .topBarTrailing {
            if viewModel.background.is(.deleting) || viewModel.background.is(.updating) {
                ProgressView()
            }

            if !isEditing {
                Button(L10n.save) {
                    viewModel.save()
                }
                .buttonStyle(.toolbarPill)
                .disabled(viewModel.background.is(.deleting) || viewModel.background.is(.updating))
            }
        }
        .onReceive(viewModel.events) { event in
            switch event {
            case .deleted, .updated:
                UIDevice.feedback(.success)
                router.dismiss()
            }
        }
        .errorMessage($viewModel.error)
    }
}
