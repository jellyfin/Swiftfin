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
        }
        .navigationBarTitle(L10n.addToPlaylist.localizedCapitalized)
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
        SplitFormWindowView()
            .descriptionView {
                playlistPosterView
            }
            .contentView {
                playlistPickerView

                playlistDetailsView

                commitButtonView
            }
    }

    // MARK: - Playlist Poster View

    private var playlistPosterView: some View {
        Group {
            if let selectedPlaylist = viewModel.selectedPlaylist {
                // TODO: This doesn't update between playlists
                ImageView(selectedPlaylist.portraitImageSources(maxWidth: 400))
            } else {
                Image(systemName: "text.badge.plus")
                    .resizable()
            }
        }
        .aspectRatio(contentMode: .fit)
        .frame(maxWidth: 400)
        .clipShape(
            RoundedRectangle(cornerRadius: 10)
        )
    }

    // MARK: - Playlist Picker View

    private var playlistPickerView: some View {
        Section {
            ListRowMenu(L10n.playlist, subtitle: viewModel.selectedPlaylist?.name ?? L10n.createPlaylist) {
                Picker(
                    L10n.playlist,
                    selection: Binding(
                        get: { viewModel.selectedPlaylist },
                        set: { newValue in
                            viewModel.send(.setPlaylist(newValue))
                        }
                    )
                ) {
                    Text(L10n.createPlaylist)
                        .tag(nil as BaseItemDto?)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    ForEach(viewModel.playlists) { playlist in
                        Text(playlist.name ?? L10n.unknown)
                            .tag(playlist as BaseItemDto?)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .font(.body)
            }
        } header: {
            Text(L10n.playlist)
        } footer: {
            if !isUnique {
                Label(
                    L10n.itemAlreadyInPlaylist(item.name ?? item.type?.displayTitle ?? L10n.items),
                    systemImage: "exclamationmark.circle.fill"
                )
            }
        }
        .background(Color.clear)
        .listRowInsets(.zero)
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
            Section(L10n.details) {
                if let mediaType = selectedPlaylist.mediaType {
                    TextPairView(leading: L10n.type, trailing: mediaType.displayTitle)
                }
                if let runTimeTicks = selectedPlaylist.runTimeTicks {
                    TextPairView(leading: L10n.duration, trailing: runTimeTicks.seconds.formatted(.hourMinute))
                }
                if let childCount = selectedPlaylist.childCount {
                    TextPairView(leading: L10n.items, trailing: childCount.description)
                }
            }
        } else {
            Section(L10n.createPlaylist) {
                TextField(L10n.name, text: $playlistName)
                    .listRowInsets(.zero)

                // TODO: Enable for 10.10
                // Toggle(L10n.public, isOn: $playlistPublic)
            }
        }
    }

    @ViewBuilder
    private var commitButtonView: some View {
        let createNewPlaylist: Bool = viewModel.selectedPlaylist == nil

        Section {
            ListRowButton(createNewPlaylist ? L10n.createPlaylist.localizedCapitalized : L10n.add) {
                if let itemID = item.id {
                    if createNewPlaylist {
                        let newPlaylist = CreatePlaylistDto(
                            ids: [itemID],
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
            .foregroundStyle(
                Color.jellyfinPurple.overlayColor,
                isValid ? Color.jellyfinPurple : Color.white.opacity(0.5)
            )
            .opacity(isValid ? 1 : 0.5)
            .listRowInsets(.zero)
        }
    }
}
