//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension RemoteView {

    struct QueueView: View {

        @Environment(\.editMode)
        private var editMode

        @ObservedObject
        var proxy: CastMediaPlayerProxy

        @Router
        private var router

        private var isEditing: Bool {
            editMode?.wrappedValue.isEditing == true
        }

        var body: some View {
            List {
                ForEach(proxy.queueItems, id: \.id) { item in
                    QueueRow(item: item, isPaused: proxy.isPaused) {
                        proxy.playQueueItem(item)
                    }
                    .isSelected(item.id == proxy.activeItem?.id)
                    .deleteDisabled(isEditing || item.id == proxy.activeItem?.id)
                }
                .onMove { source, destination in
                    proxy.queueItems.move(fromOffsets: source, toOffset: destination)

                    if !isEditing {
                        proxy.reorderQueue()
                    }
                }
                .onDelete { offsets in
                    proxy.queueItems.remove(atOffsets: offsets)

                    if !isEditing {
                        proxy.reorderQueue()
                    }
                }
            }
            .toolbarTitleDisplayMode(.inline)
            .navigationTitle(L10n.queue)
            .listStyle(.plain)
            .if(!isEditing) { view in
                view.navigationBarCloseButton {
                    router.dismiss()
                }
            }
            .navigationBarMenuButton(
                isHidden: isEditing,
                onPressed: { isPressed in
                    proxy.isSyncSuspended = isPressed
                }
            ) {
                if proxy.session.supportedCommands.contains(.setShuffleQueue) {
                    Button(L10n.shuffle, systemImage: "shuffle") {
                        proxy.shuffleQueue()
                    }
                }

                if proxy.session.supportedCommands.contains(.setRepeatMode) {
                    Menu(proxy.repeatMode.displayTitle, systemImage: proxy.repeatMode.systemImage) {
                        Picker(
                            proxy.repeatMode.displayTitle,
                            selection: Binding(
                                get: { proxy.repeatMode },
                                set: { mode in
                                    proxy.setRepeatMode(mode)
                                }
                            )
                        ) {
                            ForEach(RepeatMode.allCases, id: \.self) { mode in
                                Label(mode.displayTitle, systemImage: mode.systemImage)
                                    .tag(mode)
                            }
                        }
                    }
                }

                if proxy.queueItems.count > 1 {
                    Button(L10n.edit, systemImage: "pencil") {
                        editMode?.wrappedValue = .active
                    }
                }
            }
            .topBarTrailing {
                if isEditing {
                    Button(L10n.save) {
                        editMode?.wrappedValue = .inactive
                        proxy.reorderQueue()
                    }
                    .backport
                    .buttonStyle(.glassProminent)
                    .controlSize(.small)
                }
            }
        }
    }
}
