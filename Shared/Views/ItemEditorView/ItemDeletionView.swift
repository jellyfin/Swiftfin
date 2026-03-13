//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

// TODO: just move to a confirmation dialog on `ItemEditorView`
//       with additional warning message if deleting children

struct ItemDeletionView: View {

    @ObservedObject
    private var viewModel: ItemEditorViewModel<BaseItemDto>

    @Router
    private var router

    @State
    private var isPresentingConfirmation: Bool = false

    init(viewModel: ItemEditorViewModel<BaseItemDto>) {
        self.viewModel = viewModel
    }

    var body: some View {
        contentView
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
                Button(
                    L10n.confirm,
                    role: .destructive,
                    action: viewModel.delete
                )

                Button(L10n.cancel, role: .cancel) {}
            }
            .errorMessage($viewModel.error)
    }

    private var contentView: some View {
        Form {
            FormItemSection(item: viewModel.item)

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

                if let runtime = viewModel.item.runtime {
                    LabeledContent(
                        L10n.runtime,
                        value: runtime.formatted(.minuteSecondsNarrow)
                    )
                }

                if let startDate = viewModel.item.startDate {
                    LabeledContent(
                        L10n.startDate,
                        value: startDate.formatted(date: .complete, time: .omitted)
                    )
                }

                if let endDate = viewModel.item.endDate {
                    LabeledContent(
                        L10n.endDate,
                        value: endDate.formatted(date: .complete, time: .omitted)
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
}
