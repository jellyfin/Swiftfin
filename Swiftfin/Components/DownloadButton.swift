//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Engine
import FactoryKit
import JellyfinAPI
import SwiftUI

struct DownloadButton: View {

    @Injected(\.downloadManager)
    private var downloadManager

    @State
    private var childCount: Int?
    @State
    private var task: DownloadTask?

    private let item: BaseItemDto

    private var downloadTitle: String {
        if let childCount, childCount > 1 {
            return "\(L10n.download) (\(childCount))"
        }
        return L10n.download
    }

    init(item: BaseItemDto) {
        self.item = item
        if let id = item.id {
            self._task = State(initialValue: Container.shared.downloadManager().task(id: id))
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
                Text(L10n.deleteDownloadMessage)
            }
        }
        // Reading directly from .state locks the menus when an item is queued
        .onReceive(taskPublisher) { newTask in
            task = newTask
        }
        .onFirstAppear {
            Task {
                childCount = try? await downloadManager.downloadableItemCount(for: item)
            }
        }
    }

    private var taskPublisher: AnyPublisher<DownloadTask?, Never> {
        guard let id = item.id else {
            return Just(nil).eraseToAnyPublisher()
        }
        return downloadManager.taskPublisher(for: id)
    }

    @ViewBuilder
    private func menuContent(isPresentingDeleteConfirmation: Binding<Bool>) -> some View {
        if let id = item.id {
            if let task {
                switch task.state {
                case .queued:
                    Button(L10n.cancel, systemImage: "trash", role: .destructive) {
                        downloadManager.delete(id: id)
                    }
                case .downloading:
                    Button(L10n.pause, systemImage: "pause") {
                        downloadManager.pause(id: id)
                    }
                    Button(L10n.cancel, systemImage: "trash", role: .destructive) {
                        downloadManager.delete(id: id)
                    }
                case .paused:
                    Button(L10n.resume, systemImage: "play") {
                        downloadManager.resume(id: id)
                    }
                    Button(L10n.cancel, systemImage: "trash", role: .destructive) {
                        downloadManager.delete(id: id)
                    }
                case let .error(reason):
                    Button(reason.displayTitle, systemImage: "exclamationmark.triangle") {}
                        .disabled(true)
                    Button(L10n.retry, systemImage: "arrow.clockwise") {
                        downloadManager.resume(id: id)
                    }
                    Button(L10n.cancel, systemImage: "trash", role: .destructive) {
                        downloadManager.delete(id: id)
                    }
                case .completed:
                    Button(L10n.delete, systemImage: "trash", role: .destructive) {
                        isPresentingDeleteConfirmation.wrappedValue = true
                    }
                }
            } else {
                if downloadManager.hasSpace(for: item) {
                    Section(L10n.direct) {
                        Button(downloadTitle, systemImage: "arrow.down") {
                            downloadManager.queue(item)
                        }
                    }

                    // TODO: Transcoded downloading
                    /* Section(L10n.transcode) {
                         ForEach(PlaybackBitrate) {
                             etc etc etc
                         }
                     }*/
                } else {
                    Button(DownloadError.insufficientStorage.displayTitle, systemImage: "externaldrive.badge.exclamationmark") {}
                        .disabled(true)
                }
            }
        }
    }

    @ViewBuilder
    private var completedImage: some View {
        Image(systemName: "arrow.down.circle.fill")
            .symbolRenderingMode(.palette)
            .foregroundStyle(.white, .green)
    }

    @ViewBuilder
    private var labelView: some View {
        Group {
            if let task {
                if task.isContainer {
                    TimelineView(.periodic(from: .now, by: 0.5)) { _ in
                        if let containerTask = downloadManager.task(id: task.id),
                           downloadManager.isFullyCompleted(containerTask)
                        {
                            completedImage
                        } else {
                            ProgressView(value: downloadManager.displayProgress(for: task.id))
                                .progressViewStyle(.download)
                        }
                    }
                } else {
                    switch task.state {
                    case .downloading, .queued:
                        TimelineView(.periodic(from: .now, by: 0.1)) { _ in
                            ProgressView(value: downloadManager.displayProgress(for: task.id))
                                .progressViewStyle(.download)
                        }
                    case .paused:
                        Image(systemName: "arrow.down.circle.badge.pause")
                    case .error:
                        Image(systemName: "arrow.down.circle.badge.xmark")
                            .foregroundStyle(.red)
                    case .completed:
                        completedImage
                    }
                }
            } else {
                Image(systemName: "arrow.down.circle")
                    .foregroundStyle(downloadManager.hasSpace(for: item) ? .primary : .secondary)
            }
        }
        .id(task?.state)
        .animation(.easeInOut(duration: 0.25), value: task?.state)
    }
}
