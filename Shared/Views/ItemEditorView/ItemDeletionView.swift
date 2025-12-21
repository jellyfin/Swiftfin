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

struct ItemDeletionView: View {

    @Router
    private var router

    @ObservedObject
    private var viewModel: DeleteItemViewModel

    @State
    private var isPresentingConfirmation: Bool = false

    @State
    private var error: Error? = nil

    init(viewModel: DeleteItemViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        if let item = viewModel.item {
            contentView(item)
        } else {
            ErrorView(error: ErrorMessage(L10n.unknownError))
        }
    }

    private func contentView(_ item: BaseItemDto) -> some View {
        Form {

            #if os(tvOS)
            if let overview = item.overview {
                Section(L10n.media) {
                    if let parent = item.parentTitle {
                        LabeledContent(
                            "Parent",
                            value: parent
                        )
                    }
                    LabeledContent(
                        L10n.title,
                        value: item.displayTitle
                    )
                    if let subtitle = item.subtitle {
                        LabeledContent(
                            L10n.subtitle,
                            value: subtitle
                        )
                    }
                }
            }
            #else
            ItemFormSection(item: item)
            #endif

            if let overview = item.overview {
                Section(L10n.overview) {
                    if let taglines = item.taglines, let tagline = taglines.first {
                        Text(tagline)
                    }
                    Text(overview)
                }
            }

            Section(L10n.details) {
                if let type = item.type {
                    LabeledContent(
                        L10n.type,
                        value: type.displayTitle
                    )
                }

                if let startDate = item.startDate {
                    LabeledContent(
                        L10n.startDate,
                        value: startDate.formatted(date: .complete, time: .omitted)
                    )
                } else if let year = item.premiereDateYear {
                    LabeledContent(
                        L10n.year,
                        value: year.description
                    )
                }
            }

            if let childCount = item.childCount, childCount > 0 {
                Section {
                    LabeledContent(
                        "Children",
                        value: childCount.description
                    )
                } footer: {
                    Label("All child items (seaons, episodes, etc.) will be deleted", systemImage: "exclamationmark.circle.fill")
                        .labelStyle(.sectionFooterWithImage(imageStyle: .orange))
                }
            }

            Button(L10n.delete, role: .destructive) {
                isPresentingConfirmation = true
            }
            .buttonStyle(.primary)
        } image: {
            PosterImage(
                item: item,
                type: item.preferredPosterDisplayType,
                contentMode: .fit
            )
            .cornerRadius(20)
            .frame(maxWidth: 400)
        }
        .confirmationDialog(
            L10n.deleteItemConfirmationMessage,
            isPresented: $isPresentingConfirmation,
            titleVisibility: .visible
        ) {
            Button(L10n.confirm, role: .destructive) {
                viewModel.send(.delete)
            }
            Button(L10n.cancel, role: .cancel) {}
        }
        .onReceive(viewModel.events) { event in
            switch event {
            case .deleted:
                router.dismiss()
            case let .error(eventError):
                error = eventError
            }
        }
        .navigationTitle(L10n.deleteMedia.localizedCapitalized)
        .navigationBarCloseButton {
            router.dismiss()
        }
        .errorMessage($error)
    }
}
