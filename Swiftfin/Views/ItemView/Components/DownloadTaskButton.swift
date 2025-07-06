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

    var body: some View {
        Button {
            handleButtonTap()
        } label: {
            switch downloadTask.state {
            case .cancelled:
                Image(systemName: "arrow.down.circle")
                    .foregroundColor(.white)
            case .complete:
                Image(systemName: "arrow.down.circle")
                    .foregroundColor(.green)
            case let .downloading(progress):
                ZStack {
                    // Background circle
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 2)

                    // Progress circle
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(accentColor, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.1), value: progress)

                    // Download icon in center
                    Image(systemName: "arrow.down.circle")
                        .font(.system(size: 12))
                        .foregroundColor(accentColor)
                }
                .frame(width: 24, height: 24)
            case .error:
                Image(systemName: "arrow.down.circle")
                    .foregroundColor(.white)
            case .ready:
                Image(systemName: "arrow.down.circle")
                    .foregroundColor(.white)
            }
        }
    }

    private func handleButtonTap() {
        switch downloadTask.state {
        case .ready:
            downloadManager.download(task: downloadTask)
        case .downloading:
            downloadManager.cancel(task: downloadTask)
        case .complete, .cancelled, .error:
            // For completed downloads, we could potentially open the download details
            // or just do nothing as per requirements
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
