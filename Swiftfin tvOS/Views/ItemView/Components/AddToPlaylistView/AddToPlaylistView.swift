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

    // MARK: - Error State

    @State
    private var error: Error?

    // MARK: - Computed Variables

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
            BlurView()
                .ignoresSafeArea()

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
            .disabled(!isValid)
        }
        .onReceive(viewModel.events) { event in
            switch event {
            case .created, .updated:
                router.dismissCoordinator()
            case let .error(eventError):
                error = eventError
            }
        }
        .errorMessage($error)
        .navigationBarTitle(L10n.addToPlaylist.localizedCapitalized)
        .onFirstAppear {
            viewModel.send(.getPlaylists)
        }
    }

    // MARK: - Content View

    private var contentView: some View {
        VStack {
            Form {
                playlistPickerView
                detailsView
            }

            // MARK: Playlist Items

            if viewModel.selectedPlaylistItems.isNotEmpty {
                PosterHStack(
                    title: L10n.items,
                    type: .portrait,
                    items: viewModel.selectedPlaylistItems
                )
            }
        }
    }

    // MARK: - Playlist Picker View

    private var playlistPickerView: some View {
        Section {
            Menu {
                Button {
                    viewModel.send(.setPlaylist(nil))
                } label: {
                    HStack {
                        Text(L10n.createPlaylist)
                        if viewModel.selectedPlaylist == nil {
                            Image(systemName: "checkmark")
                        }
                    }
                }

                ForEach(viewModel.playlists) { playlist in
                    Button {
                        viewModel.send(.setPlaylist(playlist))
                    } label: {
                        HStack {
                            Text(playlist.name ?? L10n.unknown)
                            if viewModel.selectedPlaylist == playlist {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text(L10n.playlist)
                    Spacer()
                    Text(viewModel.selectedPlaylist?.name ?? L10n.createPlaylist)
                }
            }
            .listRowInsets(.zero)
        }
        header: {
            Text(L10n.playlist)
        } footer: {
            if !isUnique {
                Label(
                    L10n.itemAlreadyInPlaylist(item.name ?? item.type?.displayTitle ?? L10n.items),
                    systemImage: "exclamationmark.circle.fill"
                )
            }
        }
    }

    // MARK: - Playlist Details View

    @ViewBuilder
    private var detailsView: some View {
        if let selectedPlaylist = viewModel.selectedPlaylist {
            if let overview = selectedPlaylist.overview {
                Section(L10n.overview) {
                    Text(overview)
                }
            }
        } else {
            Section(L10n.createPlaylist) {
                TextField(L10n.name, text: $playlistName)
                    .listRowInsets(.zero)

                // TODO: Enable for 10.10
                // Toggle(L10n.public, isOn: $playlistPublic)

                InlineEnumToggle(title: L10n.type, selection: $playlistType)
            }
        }
    }
}
