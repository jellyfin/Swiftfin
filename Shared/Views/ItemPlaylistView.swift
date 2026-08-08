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

struct ItemPlaylistView: View {

    @Router
    private var router

    @StateObject
    private var viewModel: ItemPlaylistViewModel

    @State
    private var addToBeginning = false
    @State
    private var selectedPlaylistIDs: Set<String> = []

    init(item: BaseItemDto) {
        _viewModel = StateObject(wrappedValue: ItemPlaylistViewModel(item: item))
    }

    @ViewBuilder
    private var contentView: some View {
        Form(systemImage: "list.bullet") {

            Section {
                StateAdapter(initialValue: (isPresented: false, name: "")) { alert in
                    Button(L10n.newPlaylist, systemImage: "plus") {
                        alert.name.wrappedValue = ""
                        alert.isPresented.wrappedValue = true
                    }
                    .alert(L10n.newPlaylist, isPresented: alert.isPresented) {
                        TextField(L10n.name, text: alert.name)

                        Button(L10n.save) {
                            let name = alert.name.wrappedValue

                            guard name.isNotEmpty else { return }
                            viewModel.create(name: name)
                        }

                        Button(L10n.cancel, role: .cancel) {}
                    }
                }
            }

            // TODO: Remove for 13.X.
            // Position flag is ignored for pre-12.0 so this flag is hidden on 10.X to prevent confusion
            if viewModel.userSession?.server.isVersionCompatible == true {
                Section {
                    Toggle(L10n.addToBeginning, isOn: $addToBeginning)
                } footer: {
                    Text(L10n.addToBeginningDescription)
                }
            }

            Section(L10n.playlists) {
                if viewModel.playlists.isNotEmpty {
                    ForEach(viewModel.playlists) { playlist in
                        if let playlistID = playlist.id {
                            Button {
                                selectedPlaylistIDs.toggle(value: playlistID)
                            } label: {
                                HStack {
                                    Text(playlist.displayTitle)
                                        .frame(maxWidth: .infinity, alignment: .leading)

                                    ListRowCheckbox()
                                }
                            }
                            .foregroundStyle(.primary, .secondary)
                            .isEditing(true)
                            .isSelected(selectedPlaylistIDs.contains(playlistID))
                        }
                    }
                } else {
                    Text(L10n.none)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .foregroundStyle(.primary)
        .disabled(viewModel.background.is(.updating))
    }

    var body: some View {
        ZStack {
            switch viewModel.state {
            case .initial:
                ProgressView()
            case .content:
                contentView
            case .error:
                viewModel
                    .error
                    .map(ErrorView.init)
            }
        }
        .animation(.linear(duration: 0.2), value: viewModel.state)
        .navigationTitle(L10n.playlists)
        .backport
        .toolbarTitleDisplayMode(.inline)
        .navigationBarCloseButton {
            router.dismiss()
        }
        .topBarTrailing {
            if viewModel.background.is(.updating) {
                ProgressView()
            }
            Group {
                if #available(iOS 26, *) {
                    Button(L10n.save, role: .confirm) {
                        viewModel.update(
                            playlistIDs: selectedPlaylistIDs,
                            index: addToBeginning ? 0 : nil
                        )
                    }
                } else {
                    Button(L10n.save) {
                        viewModel.update(
                            playlistIDs: selectedPlaylistIDs,
                            index: addToBeginning ? 0 : nil
                        )
                    }
                    .backport
                    .buttonStyle(.glassProminent)
                    .controlSize(.small)
                }
            }
            .disabled(selectedPlaylistIDs == viewModel.containingPlaylists || viewModel.background.is(.updating))
        }
        .onFirstAppear {
            viewModel.refresh()
        }
        .onReceive(viewModel.$containingPlaylists) { containingPlaylists in
            selectedPlaylistIDs = containingPlaylists
        }
        .onReceive(viewModel.events) { event in
            switch event {
            case .updated:
                UIDevice.feedback(.success)
                router.dismiss()
            }
        }
        .errorMessage($viewModel.error)
    }
}
