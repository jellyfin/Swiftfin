//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct ItemSubtitlesView: View {

    @Router
    private var router

    @State
    private var isEditing = false
    @State
    private var isPresentingDeleteConfirmation = false
    @State
    private var selectedSubtitles: Set<MediaStream> = []

    @StateObject
    private var viewModel: ItemSubtitlesViewModel

    private var hasSubtitles: Bool {
        viewModel.externalSubtitles.isNotEmpty || viewModel.internalSubtitles.isNotEmpty
    }

    private var isAllSelected: Bool {
        selectedSubtitles.count == viewModel.externalSubtitles.count
    }

    private func toggleAllSelection() {
        selectedSubtitles = isAllSelected ? [] : Set(viewModel.externalSubtitles)
    }

    init(item: BaseItemDto) {
        self._viewModel = StateObject(wrappedValue: .init(item: item))
    }

    var body: some View {
        ZStack {
            switch viewModel.state {
            case .initial:
                ProgressView()
            case .content:
                contentView
            case .error:
                viewModel.error.map {
                    ErrorView(error: $0)
                }
            }
        }
        .onFirstAppear {
            viewModel.refresh()
        }
        .navigationTitle(L10n.subtitles)
        .navigationBarBackButtonHidden(isEditing)
        .backport
        .toolbarTitleDisplayMode(.inline)
        .errorMessage($viewModel.error)
        .if(!isEditing) { view in
            view
                .navigationBarCloseButton {
                    router.dismiss()
                }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if isEditing {
                    Button(isAllSelected ? L10n.removeAll : L10n.selectAll) {
                        toggleAllSelection()
                    }
                    .buttonStyle(.toolbarPill)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                if isEditing {
                    Button(L10n.cancel) {
                        isEditing = false
                        selectedSubtitles.removeAll()
                    }
                    .buttonStyle(.toolbarPill)
                }
            }
            ToolbarItem(placement: .bottomBar) {
                if isEditing {
                    Button(L10n.delete) {
                        isPresentingDeleteConfirmation = true
                    }
                    .buttonStyle(.toolbarPill(.red))
                    .disabled(selectedSubtitles.isEmpty)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
        .navigationBarMenuButton(
            isLoading: viewModel.background.is(.updating),
            isHidden: isEditing || !hasSubtitles
        ) {
            Button(L10n.uploadFile, systemImage: "plus") {
                router.route(to: .uploadSubtitle(viewModel: viewModel))
            }

            Button(L10n.search, systemImage: "magnifyingglass") {
                router.route(to: .searchSubtitle(viewModel: viewModel))
            }

            if viewModel.externalSubtitles.isNotEmpty {
                Button(L10n.edit, systemImage: "checkmark.circle") {
                    isEditing = true
                }
            }
        }
        .confirmationDialog(
            L10n.delete,
            isPresented: $isPresentingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(L10n.cancel, role: .cancel) {}

            Button(L10n.delete, role: .destructive) {
                viewModel.delete(selectedSubtitles)
                selectedSubtitles.removeAll()
                isEditing = false
            }
        } message: {
            Text(L10n.deleteSelectedConfirmation)
        }
    }

    @ViewBuilder
    private var contentView: some View {
        List {
            ListTitleSection(
                L10n.subtitles,
                description: L10n.manageSubtitlesDescription
            )

            if !hasSubtitles {
                Button(L10n.uploadFile, systemImage: "plus") {
                    router.route(to: .uploadSubtitle(viewModel: viewModel))
                }
                .foregroundStyle(.primary, .secondary)

                Button(L10n.search, systemImage: "magnifyingglass") {
                    router.route(to: .searchSubtitle(viewModel: viewModel))
                }
                .foregroundStyle(.primary, .secondary)
            } else {

                if viewModel.internalSubtitles.isNotEmpty {
                    Section {
                        ForEach(viewModel.internalSubtitles, id: \.index) { subtitle in
                            ItemSubtitleButton(subtitle: subtitle) {
                                router.route(to: .mediaStreamInfo(mediaStream: subtitle))
                            }
                            .disabled(isEditing)
                        }
                    } header: {
                        Text(L10n.embedded)
                    } footer: {
                        Text(L10n.embeddedSubtitleFooter)
                    }
                }

                if viewModel.externalSubtitles.isNotEmpty {
                    Section(L10n.external) {
                        ForEach(viewModel.externalSubtitles, id: \.index) { subtitle in
                            ItemSubtitleButton(subtitle: subtitle) {
                                if isEditing {
                                    selectedSubtitles.toggle(value: subtitle)
                                } else {
                                    router.route(to: .mediaStreamInfo(mediaStream: subtitle))
                                }
                            }
                            .swipeActions {
                                Button(L10n.delete, systemImage: "trash", role: .destructive) {
                                    selectedSubtitles = [subtitle]
                                    isPresentingDeleteConfirmation = true
                                }
                                .tint(.red)
                            }
                            .isEditing(isEditing)
                            .isSelected(selectedSubtitles.contains(subtitle))
                        }
                    }
                }
            }
        }
    }
}
