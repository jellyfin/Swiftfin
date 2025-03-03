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

struct AddToPlaylistView: View {

    // MARK: - Active User Session

    @Injected(\.currentUserSession)
    private var userSession

    // MARK: - Environment & State Variables

    @EnvironmentObject
    private var router: BasicNavigationViewCoordinator.Router

    @StateObject
    private var viewModel: PlaylistViewModel

    // MARK: - Media Item

    let item: BaseItemDto

    // MARK: - New Playlist Variables

    @State
    private var playlistName: String = ""
    @State
    private var playlistType: PlaylistViewModel.PlaylistType = .unknown

    // TODO: Enable for 10.10
    // @State
    // private var playlistPublic: Bool = false

    // MARK: - Edit Playlist View State

    @State
    private var isPresentingContents: Bool = false

    // MARK: - Error State

    @State
    private var error: Error?

    // MARK: - Computed Variables

    // MARK: Selected Playlist Binding

    private var selectedPlaylistBinding: Binding<BaseItemDto?> {
        Binding(
            get: { viewModel.selectedPlaylist },
            set: { newValue in
                viewModel.send(.setPlaylist(newValue))
            }
        )
    }

    // MARK: Unique State

    private var isUnique: Bool {
        !viewModel.selectedPlaylistItems.contains(where: { $0.id == item.id })
    }

    // MARK: Valid State

    private var isValid: Bool {
        // New playlist creation contains the required components
        !(viewModel.selectedPlaylist == nil && playlistName.isEmpty) &&
            // Selected playlist items are loaded
            !viewModel.backgroundStates.contains(.updatingPlaylist) &&
            // Selected playlist does not already contain this item
            isUnique
    }

    // MARK: - Initializer

    init(item: BaseItemDto) {
        self.item = item
        self._viewModel = StateObject(wrappedValue: .init())
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            switch viewModel.state {
            case .initial:
                ProgressView()
            case .content:
                contentView
            case let .error(error):
                ErrorView(error: error)
            }
        }
        .topBarTrailing {
            if viewModel.backgroundStates.contains(.updatingPlaylist) {
                ProgressView()
            }
            Button(L10n.add) {
                if let itemID = item.id {
                    if viewModel.selectedPlaylist == nil {
                        let newPlaylist = CreatePlaylistDto(
                            ids: [itemID],
                            mediaType: playlistType.rawValue,
                            name: playlistName,
                            userID: userSession?.user.id
                        )

                        viewModel.send(.createPlaylist(newPlaylist))
                    } else {
                        viewModel.send(.addItems([itemID]))
                    }
                }
            }
            .buttonStyle(.toolbarPill)
            .disabled(!isValid)
        }
        .navigationBarTitle(L10n.addToPlaylist.localizedCapitalized)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarCloseButton {
            router.dismissCoordinator()
        }
        .sheet(isPresented: $isPresentingContents) {
            isPresentingContents = false
        } content: {
            EditPlaylistView(
                viewModel: viewModel,
                onClose: {
                    isPresentingContents = false
                }
            )
        }
        .onFirstAppear {
            viewModel.send(.getPlaylists)
        }
        .onReceive(viewModel.events) { event in
            switch event {
            case .created, .added, .updated:
                router.dismissCoordinator()
            case .removed:
                break
            case let .error(eventError):
                error = eventError
            }
        }
        .errorMessage($error)
    }

    // MARK: - Content View

    private var contentView: some View {
        List {
            playlistPickerView

            playlistDetailsView
        }
    }

    // MARK: - Playlist Picker View

    private var playlistPickerView: some View {
        Section {
            Picker(L10n.playlist, selection: selectedPlaylistBinding) {
                Text(L10n.createPlaylist)
                    .tag(nil as BaseItemDto?)

                ForEach(viewModel.playlists) { playlist in
                    Text(playlist.name ?? L10n.unknown)
                        .tag(playlist as BaseItemDto?)
                }
            }
        }
        header: {
            Text(L10n.playlist)
        } footer: {
            if !isUnique {
                Label(
                    L10n.itemAlreadyInPlaylist(item.name ?? item.type?.displayTitle ?? L10n.items),
                    systemImage: "exclamationmark.circle.fill"
                )
                .labelStyle(.sectionFooterWithImage(imageStyle: .orange))
            }
        }
    }

    // MARK: - Playlist Details View

    @ViewBuilder
    private var playlistDetailsView: some View {
        if let selectedPlaylist = viewModel.selectedPlaylist {
            if let overview = selectedPlaylist.overview {
                Section(L10n.overview) {
                    Text(overview)
                }
            }

            Section(L10n.options) {
                ChevronButton(L10n.existingItems)
                    .onSelect {
                        isPresentingContents = true
                    }
            }
        } else {
            Section(L10n.createPlaylist) {
                TextField(L10n.name, text: $playlistName)

                // TODO: Enable for 10.10
                // Toggle(L10n.public, isOn: $playlistPublic)

                Picker(L10n.type, selection: $playlistType) {
                    ForEach(PlaylistViewModel.PlaylistType.allCases) { type in
                        Text(type.displayTitle)
                            .tag(type)
                    }
                }
            }
        }
    }
}
