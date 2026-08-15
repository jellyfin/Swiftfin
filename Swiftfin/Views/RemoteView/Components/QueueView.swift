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

        @ObservedObject
        var proxy: CastMediaPlayerProxy

        @State
        private var isEditing = false
        @State
        private var items: [BaseItemDto] = []

        var body: some View {
            List {
                ForEach(items, id: \.id) { item in
                    ListRow {
                        PosterImage(
                            item: item,
                            type: item.preferredPosterDisplayType,
                            contentMode: .fit
                        )
                        .frame(width: 60)
                        .subtleShadow()
                    } content: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.displayTitle)

                                if let subtitle = item.subtitle {
                                    Text(subtitle)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()

                            if item.id == proxy.activeItem?.id {
                                Image(systemName: "play.fill")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } action: {
                        proxy.playQueueItem(item)
                    }
                    .deleteDisabled(item.id == proxy.activeItem?.id)
                }
                .onMove { source, destination in
                    items.move(fromOffsets: source, toOffset: destination)

                    if !isEditing {
                        proxy.reorderQueue(items)
                    }
                }
                .onDelete { offsets in
                    items.remove(atOffsets: offsets)

                    if !isEditing {
                        proxy.reorderQueue(items)
                    }
                }
            }
            .environment(\.editMode, .constant(isEditing ? .active : .inactive))
            .backport
            .toolbarTitleDisplayMode(.inline)
            .navigationTitle(L10n.queue)
            .navigationBarMenuButton(isHidden: isEditing) {
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

                if items.count > 1 {
                    Button(L10n.edit, systemImage: "pencil") {
                        isEditing = true
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if isEditing {
                        Button(L10n.done) {
                            isEditing = false
                            proxy.reorderQueue(items)
                        }
                        .backport
                        .buttonStyle(.glassProminent)
                        .controlSize(.small)
                    }
                }
            }
            .onAppear {
                items = proxy.queueItems
            }
            .onChange(of: proxy.queueItems.compactMap(\.id)) { _, _ in
                guard !isEditing else { return }
                items = proxy.queueItems
            }
        }
    }
}
