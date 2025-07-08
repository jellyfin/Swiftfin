//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
import JellyfinAPI
import SwiftUI

struct DownloadTaskButton: View {

    @Default(.accentColor)
    private var accentColor

    @ObservedObject
    private var downloadManager: DownloadManager

    private let item: BaseItemDto
    private var onSelect: (DownloadTask) -> Void

    @State
    private var showingCancelConfirmation = false

    var body: some View {
        Button {
            handleButtonTap()
        } label: {
            switch currentTaskState {
            case .complete:
                Image(systemName: "arrow.down.circle.fill")
                    .foregroundStyle(.primary)
            case let .downloading(progress):
                CircularProgressView(progress: progress, size: 24, strokeWidth: 4)
            case .error:
                Image(systemName: "exclamationmark.circle")
                    .foregroundStyle(.red)
            case .ready, .cancelled:
                Image(systemName: "arrow.down.circle")
                    .foregroundStyle(.primary)
            }
        }
        .alert("Cancel Download", isPresented: $showingCancelConfirmation) {
            Button("Cancel Download", role: .destructive) {
                if let currentTask = currentTask {
                    downloadManager.cancel(task: currentTask)
                }
            }
            Button("Keep Downloading", role: .cancel) {
                // Do nothing, just dismiss the alert
            }
        } message: {
            Text("Are you sure you want to cancel this download? This action cannot be undone.")
        }
    }

    private var currentTask: DownloadTask? {
        downloadManager.task(for: item)
    }

    private var currentTaskState: DownloadTask.State {
        currentTask?.state ?? .ready
    }

    private func handleButtonTap() {
        guard let currentTask = currentTask else {
            // If no task exists, create a new one and start download
            let newTask = DownloadTask(item: item)
            downloadManager.download(task: newTask)
            onSelect(newTask)
            return
        }

        switch currentTask.state {
        case .ready:
            downloadManager.download(task: currentTask)
        case .downloading:
            showingCancelConfirmation = true
        case .complete, .error, .cancelled:
            // For completed downloads, we could potentially open the download details
            // or just do nothing as per requirements

            // TODO: add options for managing download - dropdown - Info, Delete ...
            break
        }

        onSelect(currentTask)
    }
}

extension DownloadTaskButton {

    init(item: BaseItemDto) {
        self.item = item
        self.downloadManager = Container.shared.downloadManager()
        self.onSelect = { _ in }
    }

    func onSelect(_ action: @escaping (DownloadTask) -> Void) -> Self {
        copy(modifying: \.onSelect, with: action)
    }
}
