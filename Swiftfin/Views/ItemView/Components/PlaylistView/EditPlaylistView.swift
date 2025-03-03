//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Factory
import JellyfinAPI
import SwiftUI

struct EditPlaylistView: View {

    // MARK: - Observed Object

    @ObservedObject
    private var viewModel: PlaylistViewModel

    // MARK: - Close Action

    private let onClose: () -> Void

    // MARK: - Remove Item Variables

    @State
    private var isPresentingRemovalConfirmation: Bool = false
    @State
    private var selectedItem: BaseItemDto? = nil

    // MARK: - Error State

    @State
    private var error: Error?

    // MARK: - Initializer

    init(viewModel: PlaylistViewModel, onClose: @escaping () -> Void) {
        self._viewModel = ObservedObject(wrappedValue: viewModel)
        self.onClose = onClose
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            ZStack {
                switch viewModel.state {
                case .initial:
                    ProgressView()
                case .content:
                    if viewModel.selectedPlaylistItems.isEmpty {
                        emptyView
                    } else {
                        contentView
                    }
                case let .error(error):
                    ErrorView(error: error)
                }
            }
            .topBarTrailing {
                if viewModel.backgroundStates.contains(.updatingPlaylist) {
                    ProgressView()
                }
            }
            .navigationBarTitle(viewModel.selectedPlaylist?.displayTitle ?? L10n.playlist)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarCloseButton {
                onClose()
            }
        }
        .confirmationDialog(
            L10n.removeItem(selectedItem?.name ?? selectedItem?.type?.displayTitle ?? L10n.items),
            isPresented: $isPresentingRemovalConfirmation
        ) {
            Button(L10n.remove, role: .destructive) {
                if let item = selectedItem {
                    viewModel.send(.removeItems([item.id!]))
                }
            }
        } message: {
            Text(L10n.removeItemConfirmationMessage)
        }
        .onReceive(viewModel.events) { event in
            switch event {
            case .created, .added, .updated:
                break
            case .removed:
                selectedItem = nil
                isPresentingRemovalConfirmation = false
            case let .error(eventError):
                error = eventError
            }
        }
        .errorMessage($error)
    }

    // MARK: - Content View

    private var contentView: some View {
        ScrollView {
            ForEach(BaseItemKind.allCases, id: \.self) { sectionType in
                let sectionItems = viewModel.selectedPlaylistItems.filter { $0.type == sectionType }

                if sectionItems.isNotEmpty {
                    PosterHStack(
                        title: sectionType.displayTitle,
                        type: .portrait,
                        items: sectionItems
                    )
                    .onSelect {
                        selectedItem = $0
                        isPresentingRemovalConfirmation = true
                    }
                }
            }
        }
    }

    // MARK: - Empty View

    private var emptyView: some View {
        Text(L10n.noResults)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}
