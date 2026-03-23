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
    private var viewModel: ItemImageViewModel

    private let imageDetail: any ItemImageDetail
    private let imageSource: ImageSource

    private var isWorking: Bool {
        viewModel.background.states.contains(.deleting) || viewModel.background.states.contains(.updating)
    }

    init(
        viewModel: ItemImageViewModel,
        imageDetail: any ItemImageDetail
    ) {
        self.viewModel = viewModel
        self.imageDetail = imageDetail
        self.imageSource = imageDetail.imageSource(
            itemID: viewModel.item.id!,
            client: viewModel.userSession.client
        )
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
                deleteButton
            }
        }
        .navigationTitle(L10n.image)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarCloseButton {
            router.dismiss()
        }
        .topBarTrailing {
            if isWorking {
                ProgressView()
            }

            if !isEditing {
                Button(L10n.save) {
                    viewModel.save()
                }
                .buttonStyle(.toolbarPill)
                .disabled(isWorking)
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

    @ViewBuilder
    private var deleteButton: some View {
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
                Button(L10n.delete, role: .destructive) {
                    viewModel.delete()
                }

                Button(L10n.cancel, role: .cancel) {
                    isPresentingConfirmation.wrappedValue = false
                }
            } message: {
                Text(L10n.deleteItemConfirmationMessage)
            }
        }
    }
}
