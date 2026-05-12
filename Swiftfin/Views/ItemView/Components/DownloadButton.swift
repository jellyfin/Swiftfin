//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Engine
import Factory
import JellyfinAPI
import SwiftUI

struct DownloadButton: View {

    @State
    private var state: DownloadState?

    private let downloadManager = Container.shared.downloadManager()

    private let item: BaseItemDto

    private var isMenu: Bool {
        state == nil || state == .paused || state == .downloading
    }

    init(item: BaseItemDto) {
        self.item = item
        let initial = Container.shared.downloadManager().records.first { $0.id == item.id }?.state
        self._state = State(initialValue: initial)
    }

    var body: some View {
        StateAdapter(initialValue: false) { isPresentingDeleteConfirmation in
            ConditionalMenu(
                isMenu: isMenu,
                action: {
                    guard let id = item.id else { return }

                    guard let state else {
                        downloadManager.queue(item)
                        return
                    }

                    switch state {
                    case .queued:
                        downloadManager.cancel(id: id)
                    case .downloading:
                        downloadManager.pause(id: id)
                    case .paused:
                        downloadManager.resume(id: id)
                    case .error:
                        downloadManager.retry(id: id)
                    case .complete:
                        isPresentingDeleteConfirmation.wrappedValue = true
                    }
                },
                menuContent: { menuView },
                label: { buttonView }
            )
            .confirmationDialog(L10n.delete, isPresented: isPresentingDeleteConfirmation) {
                Button(L10n.delete, role: .destructive) {
                    guard let id = item.id else { return }
                    downloadManager.delete(id: id)
                }
                Button(L10n.cancel, role: .cancel) {}
            } message: {
                // swiftlint:disable:next hard_coded_display_string
                Text("This will remove the downloaded file from your device.")
            }
        }
        // Reading directly from .state locks the menus when an item is queued
        .onReceive(
            downloadManager.$records
                .map { records in records.first { $0.id == item.id }?.state }
                .removeDuplicates()
        ) { newState in
            state = newState
        }
    }

    @ViewBuilder
    private var menuView: some View {
        if state == nil {
            Section(L10n.download) {
                Button(L10n.direct, systemImage: "arrow.right") {
                    downloadManager.queue(item)
                }
            }
            Section(L10n.transcode) {
                ForEach(PlaybackBitrate.supportedCases, id: \.self) { bitrate in
                    Button(bitrate.displayTitle, systemImage: "shuffle") {
                        downloadManager.queue(item, bitrate: bitrate)
                    }
                }
            }
        } else if let id = item.id, let state {
            switch state {
            case .downloading:
                Button(L10n.pause, systemImage: "pause") {
                    downloadManager.pause(id: id)
                }
                Button(L10n.cancel, systemImage: "trash", role: .destructive) {
                    downloadManager.cancel(id: id)
                }
            case .paused:
                Button(L10n.resume, systemImage: "play") {
                    downloadManager.resume(id: id)
                }
                Button(L10n.cancel, systemImage: "trash", role: .destructive) {
                    downloadManager.cancel(id: id)
                }
            default:
                EmptyView()
            }
        }
    }

    @ViewBuilder
    private var buttonView: some View {
        Group {
            switch state {
            case .downloading, .queued:
                TimelineView(.periodic(from: .now, by: 0.1)) { _ in
                    ProgressView(value: downloadManager.records.first { $0.id == item.id }?.progress ?? 0)
                        .progressViewStyle(.download)
                }
            case .paused:
                Image(systemName: "arrow.down.circle.badge.pause")
            case .complete:
                Image(systemName: "arrow.down.circle.fill")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .green)
            case .error:
                Image(systemName: "arrow.down.circle.badge.xmark")
                    .foregroundStyle(.red)
            case .none:
                Image(systemName: "arrow.down.circle")
            }
        }
        .id(state)
        .animation(.easeInOut(duration: 0.25), value: state)
    }
}
