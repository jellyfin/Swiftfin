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

struct ItemPlaylistView: View {

    @Injected(\.currentUserSession)
    private var userSession

    @EnvironmentObject
    private var router: BasicNavigationViewCoordinator.Router

    let item: BaseItemDto

    @StateObject
    var viewModel: PlaylistViewModel

    @State
    private var playlistName: String = ""
    @State
    private var playlistType: PlaylistViewModel.PlaylistType = .unknown

    @State
    private var error: Error?

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
            case .content, .updating:
                contentView
            case let .error(error):
                ErrorView(error: error)
            }
        }
        .topBarTrailing {
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
            .disabled(viewModel.selectedPlaylist == nil && playlistName.isEmpty)
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
        .navigationBarTitle("Add to Playlist")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarCloseButton {
            router.dismissCoordinator()
        }
        .onFirstAppear {
            viewModel.send(.getPlaylists)
        }
    }

    // MARK: - Content View

    private var contentView: some View {
        VStack {
            List {
                Section {
                    Picker("Playlist", selection: selectedPlaylistBinding) {
                        Text("Create new")
                            .tag(nil as BaseItemDto?)

                        ForEach(viewModel.playlists) { playlist in
                            Text(playlist.name ?? L10n.unknown)
                                .tag(playlist as BaseItemDto?)
                        }
                    }
                }

                if let selectedPlaylist = viewModel.selectedPlaylist {
                    if let overview = selectedPlaylist.overview {
                        Section(L10n.overview) {
                            Text(overview)
                        }
                    }
                } else {
                    Section("Create playlist") {
                        TextField(L10n.name, text: $playlistName)

                        Picker(L10n.type, selection: $playlistType) {
                            ForEach(PlaylistViewModel.PlaylistType.allCases) { type in
                                Text(type.displayTitle)
                                    .tag(type)
                            }
                        }
                    }
                }
            }

            // MARK: Items

            if viewModel.items.isNotEmpty {
                PosterHStack(
                    title: L10n.items,
                    type: .portrait,
                    items: viewModel.items
                )
            }
        }
    }

    // MARK: - Selected Playlist Binding

    private var selectedPlaylistBinding: Binding<BaseItemDto?> {
        Binding(
            get: { viewModel.selectedPlaylist },
            set: { newValue in
                viewModel.send(.setPlaylist(newValue))
            }
        )
    }
}
