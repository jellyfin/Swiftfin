//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Combine
import Factory
import Foundation

#if DEBUG
enum DownloadTaskState {
    case ready
    case downloading
    case paused
    case error
    case partiallyCompleted
    case completed
}
#endif

// MARK: - DownloadTaskState Enum (if not already defined elsewhere)

// Remove this if DownloadTask.State is imported from your DownloadTask module
// enum DownloadTaskState: Equatable {
//     case ready, downloading, paused, complete, cancelled, error
// }

// MARK: - ViewModel

@MainActor
final class DownloadActionButtonWithProgressViewModel: ObservableObject {
    // Published properties for state and progress
    @Published
    var state: DownloadTaskState
    @Published
    var progress: Double // 0.0 ... 1.0

    private var cancellables = Set<AnyCancellable>()

    // Optionally, reference to the download task (if needed)
    // private let downloadTask: DownloadTask

    private let downloadTask: DownloadTask?

    @Injected(\.downloadManager)
    private var downloadManager: DownloadManager

    init(downloadTask: DownloadTask? = nil, state: DownloadTaskState = .ready, progress: Double = 0.0) {
        self.downloadTask = downloadTask
        self.state = state
        self.progress = progress
    }

    // Example: Update state and progress from a download task publisher
    func bind(to publisher: AnyPublisher<(DownloadTaskState, Double), Never>) {
        publisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state, progress in
                self?.state = state
                self?.progress = progress
            }
            .store(in: &cancellables)
    }

    // TODO: - dummy logic

    func start() {
        self.state = .downloading
        self.progress = 0.42
    }

    func pause() {
        self.state = .paused
    }

    func resume() {
        self.progress = 0.84
        self.state = .completed
    }

    func cancel() {
        self.state = .completed
    }
}
