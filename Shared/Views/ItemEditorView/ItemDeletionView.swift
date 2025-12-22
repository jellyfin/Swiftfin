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
    private var viewModel: ItemEditorViewModel<BaseItemDto>

    @State
    private var isPresentingConfirmation: Bool = false

    init(viewModel: ItemEditorViewModel<BaseItemDto>) {
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack {
            switch viewModel.state {
            case .initial:
                contentView
            case .error:
                viewModel.error.map {
                    ErrorView(error: $0)
                }
            }
        }
        .navigationTitle(L10n.deleteMedia.localizedCapitalized)
        .navigationBarCloseButton {
            router.dismiss()
        }
        .onReceive(viewModel.events) { event in
            switch event {
            case .deleted:
                UIDevice.feedback(.success)
                router.dismiss()
            case .metadataRefreshStarted, .updated:
                break
            }
        }
        .confirmationDialog(
            L10n.deleteItemConfirmationMessage,
            isPresented: $isPresentingConfirmation,
            titleVisibility: .visible
        ) {
            Button(L10n.confirm, role: .destructive) {
                viewModel.delete()
            }
            Button(L10n.cancel, role: .cancel) {}
        }
        .errorMessage($viewModel.error)
    }

    private var contentView: some View {
        Form {

            headerView

            if let overview = viewModel.item.overview {
                Section(L10n.overview) {
                    if let taglines = viewModel.item.taglines, let tagline = taglines.first {
                        Text(tagline)
                    }
                    Text(overview)
                }
            }

            Section(L10n.details) {
                if let type = viewModel.item.type {
                    LabeledContent(
                        L10n.type,
                        value: type.displayTitle
                    )
                }

                if let startDate = viewModel.item.startDate {
                    LabeledContent(
                        L10n.startDate,
                        value: startDate.formatted(date: .complete, time: .omitted)
                    )
                } else if let year = viewModel.item.premiereDateYear {
                    LabeledContent(
                        L10n.year,
                        value: year.description
                    )
                }
            }

            if let childCount = viewModel.item.childCount, childCount > 0 {
                Section {
                    LabeledContent(
                        L10n.children,
                        value: childCount.description
                    )
                } footer: {
                    Label(L10n.childDeletionWarning, systemImage: "exclamationmark.circle.fill")
                        .labelStyle(.sectionFooterWithImage(imageStyle: .orange))
                }
            }

            Button(L10n.delete, role: .destructive) {
                isPresentingConfirmation = true
            }
            .buttonStyle(.primary)
        } image: {
            PosterImage(
                item: viewModel.item,
                type: viewModel.item.preferredPosterDisplayType,
                contentMode: .fit
            )
            .cornerRadius(20)
            .frame(maxWidth: 400)
        }
    }

    @ViewBuilder
    private var headerView: some View {
        #if os(tvOS)
        if let overview = viewModel.item.overview {
            Section(L10n.media) {
                if let parent = viewModel.item.parentTitle {
                    LabeledContent(
                        "Parent",
                        value: parent
                    )
                }
                LabeledContent(
                    L10n.title,
                    value: viewModel.item.displayTitle
                )
                if let subtitle = viewModel.item.subtitle {
                    LabeledContent(
                        L10n.subtitle,
                        value: subtitle
                    )
                }
            }
        }
        #else
        ItemFormSection(item: viewModel.item)
        #endif
    }
}
