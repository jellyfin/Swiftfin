//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension PlaylistItemView {

    struct ContentView: View {

        // MARK: - Environment

        @EnvironmentObject
        private var router: ItemCoordinator.Router

        // MARK: - View-Models

        @ObservedObject
        private var viewModel: PlaylistItemViewModel

        @StateObject
        private var editorViewModel: PlaylistEditorViewModel

        // MARK: - Drag State

        @State
        private var draggedID: String?
        @State
        private var lastTargetID: String?

        // MARK: - Init

        init(viewModel: PlaylistItemViewModel) {
            self.viewModel = viewModel
            _editorViewModel = StateObject(
                wrappedValue: PlaylistEditorViewModel(
                    playlist: viewModel.item,
                    playlistItems: viewModel.playlistItems
                )
            )
        }

        // MARK: - Body

        var body: some View {
            if editorViewModel.selectedPlaylistItems.isEmpty {
                Text(L10n.none)
            } else {
                LazyVStack {
                    ForEach(editorViewModel.selectedPlaylistItems, id: \.id) { item in
                        ItemView.PlaylistItemRow(item: item) {
                            router.route(to: \.item, item)
                        }
                        .background(draggedID == item.id ? Color.gray.opacity(0.2) : .clear)
                        .contextMenu { removeButton(for: item) }
                        .onDrag { startDrag(item) }
                        .onDrop(
                            of: [.text],
                            delegate: ReorderDelegate(
                                targetID: item.id,
                                draggedID: $draggedID,
                                lastTargetID: $lastTargetID,
                                editor: editorViewModel
                            )
                        )
                    }
                }
                .animation(.easeInOut, value: editorViewModel.selectedPlaylistItems)
                .onDrop(
                    of: [.text],
                    delegate: BackgroundDropDelegate(
                        draggedID: $draggedID,
                        lastTargetID: $lastTargetID
                    )
                )
            }
        }

        // MARK: - Helpers

        private func startDrag(_ item: BaseItemDto) -> NSItemProvider {
            draggedID = item.id
            lastTargetID = nil
            return NSItemProvider(object: (item.id ?? "unknown") as NSString)
        }

        @ViewBuilder
        private func removeButton(for item: BaseItemDto) -> some View {
            if let id = item.id {
                Button(role: .destructive) {
                    editorViewModel.send(.removeItems([id]))
                } label: {
                    Label("Remove from playlist", systemImage: "text.badge.minus")
                }
            }
        }
    }

    // MARK: - Drop Delegate (Row)

    private struct ReorderDelegate: DropDelegate {
        let targetID: String?
        @Binding
        var draggedID: String?
        @Binding
        var lastTargetID: String?
        let editor: PlaylistEditorViewModel

        func dropEntered(info: DropInfo) {
            guard let sourceID = draggedID,
                  let destID = targetID,
                  sourceID != destID,
                  lastTargetID != destID,
                  let destIndex = editor.selectedPlaylistItems.firstIndex(where: { $0.id == destID })
            else { return }

            withAnimation(.easeInOut) {
                editor.send(.moveItem(itemID: sourceID, index: destIndex))
            }
            lastTargetID = destID
        }

        func dropUpdated(info: DropInfo) -> DropProposal? { .init(operation: .move) }

        func performDrop(info: DropInfo) -> Bool {
            draggedID = nil
            lastTargetID = nil
            return true
        }
    }

    // MARK: - Drop Delegate (Background)

    private struct BackgroundDropDelegate: DropDelegate {
        @Binding
        var draggedID: String?
        @Binding
        var lastTargetID: String?

        func performDrop(info: DropInfo) -> Bool {
            draggedID = nil
            lastTargetID = nil
            return true
        }
    }
}
