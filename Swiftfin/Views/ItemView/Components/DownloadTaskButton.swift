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
    @ObservedObject
    private var downloadTask: DownloadTask

    private var onSelect: (DownloadTask) -> Void

    @State
    private var showingCancelConfirmation = false

    var body: some View {
        Button {
            handleButtonTap()
        } label: {
            switch downloadTask.state {
            case .cancelled:
                Image(systemName: "arrow.down.circle")
                    .foregroundStyle(.red)
            case .complete:
                Image(systemName: "arrow.down.circle.fill")
                    .foregroundStyle(.purple)
            case let .downloading(progress):
                CircularProgressView(progress: progress, size: 24, strokeWidth: 4)
            case .error:
                Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(.red)
            case .ready:
                Image(systemName: "arrow.down.circle")
                    .foregroundStyle(.gray)
            }
        }
        .alert("Cancel Download", isPresented: $showingCancelConfirmation) {
            Button("Cancel Download", role: .destructive) {
                downloadManager.cancel(task: downloadTask)
            }
            Button("Keep Downloading", role: .cancel) {
                // Do nothing, just dismiss the alert
            }
        } message: {
            Text("Are you sure you want to cancel this download? This action cannot be undone.")
        }
    }

    private func handleButtonTap() {
        switch downloadTask.state {
        case .ready:
            downloadManager.download(task: downloadTask)
        case .downloading:
            showingCancelConfirmation = true
        case .complete, .cancelled, .error:
            // For completed downloads, we could potentially open the download details
            // or just do nothing as per requirements

            // TODO: add options for managing download - dropdown - Info, Delete ...
            break
        }

        onSelect(downloadTask)
    }
}

extension DownloadTaskButton {

    init(item: BaseItemDto) {
        let downloadManager = Container.shared.downloadManager()

        self.downloadTask = downloadManager.task(for: item) ?? .init(item: item)
        self.onSelect = { _ in }
        self.downloadManager = downloadManager
    }

    func onSelect(_ action: @escaping (DownloadTask) -> Void) -> Self {
        copy(modifying: \.onSelect, with: action)
    }
}
