//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI
import UniformTypeIdentifiers

// TODO: Localize

struct ItemSubtitlesView: View {

    // MARK: - Properties

    @EnvironmentObject
    private var router: ItemEditorCoordinator.Router

    @StateObject
    private var viewModel: ItemSubtitlesViewModel

    // MARK: - Edit Mode

    @State
    private var isEditing = false

    // MARK: - Subtitle State

    @State
    private var expandedSubtitle: MediaStream?

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
        .navigationBarTitle(L10n.subtitles)
        .navigationBarBackButtonHidden(isEditing)
        .navigationBarTitleDisplayMode(.inline)
        .onReceive(viewModel.events) { event in
            if case let .error(eventError) = event {
                error = eventError
            }
        }
        .errorMessage($error)
        .onFirstAppear {
            viewModel.send(.search(language: "English"))
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if isEditing {
                    Button(isAllSelected ? L10n.removeAll : L10n.selectAll) {
                        selectedSubtitles = isAllSelected ? [] : Set(viewModel.externalSubtitles)
                    }
                    .buttonStyle(.toolbarPill)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                if isEditing {
                    Button(L10n.cancel) {
                        isEditing = false
                        UIDevice.impact(.light)
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
            isLoading: viewModel.backgroundStates.contains(.updating),
            isHidden: isEditing || !hasSubtitles
        ) {
            Button(L10n.uploadFile, systemImage: "plus") {
                router.route(to: \.uploadSubtitle, viewModel)
            }

            Button(L10n.search, systemImage: "magnifyingglass") {
                router.route(to: \.searchSubtitle, viewModel)
            }

            if viewModel.externalSubtitles.isNotEmpty {
                Button(L10n.edit, systemImage: "checkmark.circle") {
                    isEditing = true
                }
            }
        }
        .sheet(isPresented: .constant(expandedSubtitle != nil), onDismiss: { expandedSubtitle = nil }) {
            expandedSubtitleSheet
        }
        .confirmationDialog(
            L10n.delete,
            isPresented: $isPresentingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            deleteConfirmationActions {
                isPresentingDeleteConfirmation = false
            }
        } message: {
            Text(L10n.deleteSelectedConfirmation)
        }
    }

    // MARK: - Content Views

    private var contentView: some View {
        List {
            ListTitleSection(
                L10n.subtitles,
                description: "Delete, upload, or search for external subtitles"
            )

            if !hasSubtitles {
                Text(L10n.none)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .listRowSeparator(.hidden)
                    .listRowInsets(.zero)
            } else {
                if viewModel.internalSubtitles.isNotEmpty {
                    Section {
                        DisclosureGroup("Embedded") {
                            ForEach(viewModel.internalSubtitles, id: \.index) { subtitle in
                                SubtitleButton(subtitle) {
                                    expandedSubtitle = subtitle
                                }
                                .environment(\.isEnabled, !isEditing)
                            }
                        }
                    } footer: {
                        Text("Embedded subtitles cannot be edited.")
                    }
                }
                if viewModel.externalSubtitles.isNotEmpty {
                    Section {
                        DisclosureGroup(L10n.external) {
                            ForEach(viewModel.externalSubtitles, id: \.index) { subtitle in
                                SubtitleButton(subtitle) {
                                    if isEditing {
                                        toggleSelection(for: subtitle)
                                    } else {
                                        expandedSubtitle = subtitle
                                    }
                                } onDelete: {
                                    selectedSubtitles = [subtitle]
                                    isPresentingDeleteConfirmation = true
                                }
                                .environment(\.isSelected, selectedSubtitles.contains(subtitle))
                                .environment(\.isEditing, isEditing)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Subtitle Detail Sheet

    @ViewBuilder
    private var expandedSubtitleSheet: some View {
        NavigationView {
            if let mediaStream = expandedSubtitle {
                MediaStreamInfoView(mediaStream: mediaStream)
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationBarCloseButton {
                        expandedSubtitle = nil
                    }
            }
        }
    }

    // MARK: - Add/Remove Selected Subtitle

    private func toggleSelection(for subtitle: MediaStream) {
        if selectedSubtitles.contains(subtitle) {
            selectedSubtitles.remove(subtitle)
        } else {
            selectedSubtitles.insert(subtitle)
        }
    }

    // MARK: - Delete Confirmation Actions

    @ViewBuilder
    private func deleteConfirmationActions(onDelete: @escaping () -> Void) -> some View {
        Button(L10n.cancel, role: .cancel) {}

        Button(L10n.delete, role: .destructive) {

            viewModel.send(.delete(selectedSubtitles))
            selectedSubtitles.removeAll()
            isEditing = false
            isPresentingDeleteConfirmation = false
        }
    }
}
