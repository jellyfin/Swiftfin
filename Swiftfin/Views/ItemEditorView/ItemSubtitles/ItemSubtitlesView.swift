//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct ItemSubtitlesView: View {

    // MARK: - Router

    @Router
    private var router

    // MARK: - ViewModel

    @StateObject
    private var viewModel: SubtitleEditorViewModel

    // MARK: - Edit Mode

    @State
    private var isEditing = false

    // MARK: - Deletion Dialog States

    @State
    private var selectedSubtitles: Set<MediaStream> = []
    @State
    private var isPresentingDeleteConfirmation = false

    // MARK: - Error State

    @State
    private var error: Error?

    // MARK: - Item has Subtitles

    private var hasSubtitles: Bool {
        viewModel.externalSubtitles.isNotEmpty || viewModel.internalSubtitles.isNotEmpty
    }

    // MARK: - All Subtitles Selected

    private var isAllSelected: Bool {
        selectedSubtitles.count == viewModel.externalSubtitles.count
    }

    // MARK: - Initializer

    init(item: BaseItemDto) {
        self._viewModel = StateObject(wrappedValue: .init(item: item))
    }

    // MARK: - Toggle All Selection

    private func toggleAllSelection() {
        selectedSubtitles = isAllSelected ? [] : Set(viewModel.externalSubtitles)
    }

    // MARK: - Cancel Editing

    private func cancelEditing() {
        isEditing = false
        UIDevice.impact(.light)
        selectedSubtitles.removeAll()
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            switch viewModel.state {
            case let .error(error):
                ErrorView(error: error)
            default:
                contentView
            }
        }
        .navigationTitle(L10n.subtitles)
        .navigationBarBackButtonHidden(isEditing)
        .navigationBarTitleDisplayMode(.inline)
        .onReceive(viewModel.events) { event in
            if case let .error(eventError) = event {
                error = eventError
            }
        }
        .errorMessage($error)
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
                        cancelEditing()
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
            isLoading: viewModel.backgroundStates.contains(.updating),
            isHidden: isEditing || !hasSubtitles
        ) {
            Section(L10n.add) {
                Button(L10n.uploadFile, systemImage: "plus") {
                    router.route(to: .uploadSubtitle(viewModel: viewModel))
                }

                Button(L10n.search, systemImage: "magnifyingglass") {
                    router.route(to: .searchSubtitle(viewModel: viewModel))
                }
            }

            if viewModel.externalSubtitles.isNotEmpty {
                Section(L10n.manage) {
                    Button(L10n.edit, systemImage: "checkmark.circle") {
                        isEditing = true
                    }
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
                viewModel.send(.delete(selectedSubtitles))
                selectedSubtitles.removeAll()
                isEditing = false
                isPresentingDeleteConfirmation = false
            }
        } message: {
            Text(L10n.deleteSelectedConfirmation)
        }
    }

    // MARK: - Content Views

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
            }

            if viewModel.internalSubtitles.isNotEmpty {
                Section {
                    DisclosureGroup(L10n.embedded) {
                        ForEach(viewModel.internalSubtitles, id: \.index) { subtitle in
                            SubtitleButton(subtitle) {
                                router.route(to: .mediaStreamInfo(mediaStream: subtitle))
                            }
                            .environment(\.isEnabled, !isEditing)
                        }
                    }
                } footer: {
                    Text(L10n.embeddedSubtitleFooter)
                }
            }

            if viewModel.externalSubtitles.isNotEmpty {
                Section {
                    DisclosureGroup(L10n.external) {
                        ForEach(viewModel.externalSubtitles, id: \.index) { subtitle in
                            SubtitleButton(subtitle) {
                                if isEditing {
                                    selectedSubtitles.toggle(value: subtitle)
                                } else {
                                    router.route(to: .mediaStreamInfo(mediaStream: subtitle))
                                }
                            } deleteAction: {
                                selectedSubtitles = [subtitle]
                                isPresentingDeleteConfirmation = true
                            }
                            .isSelected(selectedSubtitles.contains(subtitle))
                            .isEditing(isEditing)
                        }
                    }
                }
            }
        }
    }
}
