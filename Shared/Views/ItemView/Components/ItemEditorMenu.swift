//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct ItemEditorMenu: View {

    @Router
    private var router

    @ObservedObject
    private var viewModel: ItemViewModel

    @State
    private var isPresentingConfirmationDialog = false

    @StateObject
    private var deleteViewModel: DeleteItemViewModel

    init(viewModel: ItemViewModel) {
        self.viewModel = viewModel
        self._deleteViewModel = StateObject(wrappedValue: DeleteItemViewModel(item: viewModel.item))
    }

    @ViewBuilder
    var body: some View {
        contentView
            .confirmationDialog(
                L10n.deleteItemConfirmationMessage,
                isPresented: $isPresentingConfirmationDialog,
                titleVisibility: .visible
            ) {
                Button(L10n.confirm, role: .destructive) {
                    deleteViewModel.send(.delete)
                }
                Button(L10n.cancel, role: .cancel) {}
            }
            .onReceive(deleteViewModel.events) { event in
                switch event {
                case .deleted:
                    router.dismiss()
                case .error:
                    break
                }
            }
        // TODO: Move over when @Stateful
        // .errorMessage($deleteViewModel.error)
    }

    @ViewBuilder
    private var contentView: some View {
        if viewModel.item.canEditMetadata {
            Button(L10n.refreshMetadata, systemImage: "arrow.clockwise") {
                router.route(to: .itemMetadataRefresh(viewModel: .init(item: viewModel.item)))
            }
            #if os(iOS)
            Button(L10n.metadata, systemImage: "pencil") {
                router.route(to: .itemEditor(viewModel: viewModel))
            }
            #endif
        }

        // TODO: Enable when Music & Lyrics are added
        /* if viewModel.item.canEditLyrics {
            Button(L10n.lyrics, systemImage: "music.note.list") {
                 #if os(iOS)
                 router.route(to: .editLyrics(item: viewModel.item))
                 #else
                 router.route(to: .searchLyrics(viewModel: .init(item: viewModel.item)))
                 #endif
         }*/

        if viewModel.item.canEditSubtitles {
            Button(L10n.subtitles, systemImage: "captions.bubble") {
                #if os(iOS)
                router.route(to: .editSubtitles(item: viewModel.item))
                #else
                router.route(to: .searchSubtitle(viewModel: .init(item: viewModel.item)))
                #endif
            }
        }

        if viewModel.item.canBeDeleted {
            Section {
                Button(L10n.delete, systemImage: "trash", role: .destructive) {
                    isPresentingConfirmationDialog = true
                }
            }
        }
    }
}
