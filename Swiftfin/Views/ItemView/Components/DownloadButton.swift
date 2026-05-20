//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Engine
import Factory
import JellyfinAPI
import SwiftUI

struct DownloadButton: View {

    @State
    private var state: ItemDownloadState = .none

    private let downloadManager = Container.shared.downloadManager()

    private let item: BaseItemDto

    init(item: BaseItemDto) {
        self.item = item
        if let id = item.id {
            self._state = State(initialValue: Container.shared.downloadManager().state(forItemID: id))
        }
    }

    var body: some View {
        StateAdapter(initialValue: false) { isPresentingDeleteConfirmation in
            Menu {
                menuContent(isPresentingDeleteConfirmation: isPresentingDeleteConfirmation)
            } label: {
                labelView
            }
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
        .onReceive(statePublisher) { newState in
            state = newState
        }
    }

    private var statePublisher: AnyPublisher<ItemDownloadState, Never> {
        guard let id = item.id else {
            return Just(.none).eraseToAnyPublisher()
        }
        return downloadManager.statePublisher(for: id)
    }

    @ViewBuilder
    private func menuContent(isPresentingDeleteConfirmation: Binding<Bool>) -> some View {
        if let id = item.id {
            switch state {
            case .none:
                if downloadManager.canDownload(item) {
                    Button(L10n.download, systemImage: "arrow.down") {
                        downloadManager.queue(item)
                    }
                } else {
                    // swiftlint:disable:next hard_coded_display_string
                    Button(DownloadError.insufficientStorage.displayTitle, systemImage: "externaldrive.badge.exclamationmark") {}
                        .disabled(true)
                }
            case let .active(task):
                switch task.state {
                case .queued:
                    Button(L10n.cancel, systemImage: "trash", role: .destructive) {
                        downloadManager.cancel(id: id)
                    }
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
                case let .error(reason):
                    Button(reason.displayTitle, systemImage: "exclamationmark.triangle") {}
                        .disabled(true)
                    Button(L10n.retry, systemImage: "arrow.clockwise") {
                        downloadManager.retry(id: id)
                    }
                    Button(L10n.cancel, systemImage: "trash", role: .destructive) {
                        downloadManager.cancel(id: id)
                    }
                }
            case .downloaded:
                Button(L10n.delete, systemImage: "trash", role: .destructive) {
                    isPresentingDeleteConfirmation.wrappedValue = true
                }
            }
        }
    }

    @ViewBuilder
    private var labelView: some View {
        Group {
            switch state {
            case .none:
                Image(systemName: "arrow.down.circle")
                    .foregroundStyle(downloadManager.canDownload(item) ? .primary : .secondary)
            case let .active(task):
                switch task.state {
                case .downloading, .queued:
                    TimelineView(.periodic(from: .now, by: 0.1)) { _ in
                        ProgressView(value: downloadManager.task(id: task.id)?.progress ?? 0)
                            .progressViewStyle(.download)
                    }
                case .paused:
                    Image(systemName: "arrow.down.circle.badge.pause")
                case .error:
                    Image(systemName: "arrow.down.circle.badge.xmark")
                        .foregroundStyle(.red)
                }
            case .downloaded:
                Image(systemName: "arrow.down.circle.fill")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .green)
            }
        }
        .id(state)
        .animation(.easeInOut(duration: 0.25), value: state)
    }
}
