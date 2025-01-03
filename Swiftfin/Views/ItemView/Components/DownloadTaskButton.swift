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

struct DownloadTaskButton: View {

    @ObservedObject
    private var downloadManager: DownloadManager
    @ObservedObject
    private var downloadTask: DownloadTask

    private var onSelect: (DownloadTask) -> Void

    var body: some View {
        Button {
            onSelect(downloadTask)
        } label: {
            switch downloadTask.state {
            case .cancelled:
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(.red)
            case .complete:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            case .downloading:
                EmptyView()
//                CircularProgressView(progress: progress)
            case .error:
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(.red)
            case .ready:
                Image(systemName: "arrow.down.circle")
            }
        }
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
