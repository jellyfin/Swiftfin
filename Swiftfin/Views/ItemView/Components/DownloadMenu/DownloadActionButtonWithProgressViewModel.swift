//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation

#if DEBUG
enum DownloadTaskState {
    case ready
    case downloading
    case finished
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

    init(state: DownloadTaskState = .ready, progress: Double = 0.0) {
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

    // Example: Actions
    func pause() {
        // Implement pause logic
    }

    func resume() {
        // Implement resume logic
    }

    func cancel() {
        // Implement cancel logic
    }
}
