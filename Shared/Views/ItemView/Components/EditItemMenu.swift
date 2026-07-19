//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

extension ItemView {

    struct EditItemMenu<LabelContent: View>: PlatformView {

        @Router
        private var router

        @StateObject
        private var viewModel: ItemEditorViewModel

        private let label: LabelContent

        init(item: BaseItemDto, @ViewBuilder label: () -> LabelContent) {
            self._viewModel = StateObject(wrappedValue: ItemEditorViewModel(item: item))
            self.label = label()
        }

        @ViewBuilder
        private var menuContent: some View {
            Group {
                if viewModel.item.canEditMetadata {
                    #if os(iOS)
                    Button(L10n.edit, systemImage: "pencil") {
                        router.route(to: .itemEditor(viewModel: viewModel))
                    }
                    #endif
                    Button(L10n.refreshMetadata, systemImage: "arrow.clockwise") {
                        router.route(to: .itemMetadataRefresh(viewModel: viewModel))
                    }
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
            }
            .symbolRenderingMode(.monochrome)
            .foregroundStyle(.primary)
        }

        var iOSView: some View {
            menuContent
                .onNotification(.didDeleteItem) { _ in
                    UIDevice.feedback(.success)
                    router.dismiss()
                }
                .errorMessage($viewModel.error)
        }

        var tvOSView: some View {
            StateAdapter(initialValue: false) { isPresentingDeleteConfirmation in
                Menu {
                    menuContent

                    if viewModel.item.canDeleteItem {
                        Divider()

                        Button(L10n.delete, systemImage: "trash", role: .destructive) {
                            isPresentingDeleteConfirmation.wrappedValue = true
                        }
                    }
                } label: {
                    label
                }
                .menuStyle(.button)
                .confirmationDialog(
                    L10n.deleteItemConfirmationMessage,
                    isPresented: isPresentingDeleteConfirmation,
                    titleVisibility: .visible
                ) {
                    Button(
                        L10n.confirm,
                        role: .destructive,
                        action: viewModel.delete
                    )

                    Button(L10n.cancel, role: .cancel) {}
                }
                .onNotification(.didDeleteItem) { _ in
                    router.dismiss()
                }
                .errorMessage($viewModel.error)
            }
        }
    }
}

extension ItemView.EditItemMenu where LabelContent == EmptyView {

    init(item: BaseItemDto) {
        self.init(item: item) { EmptyView() }
    }
}
