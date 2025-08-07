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
import JellyfinAPI

// MARK: - DownloadTaskState Enum for UI

enum DownloadTaskState {
    case ready
    case downloading
    case paused
    case error
    case partiallyCompleted
    case completed
}

// MARK: - ViewModel

@MainActor
final class DownloadActionButtonWithProgressViewModel: ObservableObject {
    // Published properties for state and progress
    @Published
    var state: DownloadTaskState = .ready
    @Published
    var progress: Double = 0.0 // 0.0 ... 1.0

    private var cancellables = Set<AnyCancellable>()
    private var downloadTask: DownloadTask?
    private var taskID: UUID?

    // Item and media source information
    private let item: BaseItemDto?
    private let mediaSourceId: String?

    @Injected(\.downloadManager)
    private var downloadManager: DownloadManager

    // MARK: - Initializers

    /// Initialize with an existing download task
    init(downloadTask: DownloadTask) {
        self.downloadTask = downloadTask
        self.item = downloadTask.item
        self.mediaSourceId = downloadTask.mediaSourceId
        self.taskID = downloadTask.taskID

        setupStateObservation()
    }

    /// Initialize with an item and optional media source for new downloads
    init(item: BaseItemDto, mediaSourceId: String? = nil) {
        self.item = item
        self.mediaSourceId = mediaSourceId
        // Find the specific download task that matches both item and mediaSourceId
        self.downloadTask = downloadManager.downloads.first { task in
            task.item.id == item.id && task.mediaSourceId == mediaSourceId
        }
        self.taskID = downloadTask?.taskID

        setupStateObservation()
    }

    /// Initialize for testing/preview purposes
    init(state: DownloadTaskState = .ready, progress: Double = 0.0) {
        self.item = nil
        self.mediaSourceId = nil
        self.state = state
        self.progress = progress
    }

    // MARK: - State Management

    private func setupStateObservation() {
        // Observe download manager's downloads array for changes to our task
        downloadManager.$downloads
            .sink { [weak self] downloads in
                guard let self = self, let itemId = self.item?.id else { return }

                // Find our specific task in the downloads array by both item ID and media source ID
                let currentTask = downloads.first { task in
                    task.item.id == itemId && task.mediaSourceId == self.mediaSourceId
                }

                // Update our references
                self.downloadTask = currentTask
                self.taskID = currentTask?.taskID

                // Update UI state
                self.updateStateFromDownloadTask(currentTask)
            }
            .store(in: &cancellables)

        // Set up a timer to periodically check task state (for real-time progress updates)
        Timer.publish(every: 0.5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, let task = self.downloadTask else { return }
                self.updateStateFromDownloadTask(task)
            }
            .store(in: &cancellables)
    }

    private func updateStateFromDownloadTask(_ task: DownloadTask?) {
        guard let task = task else {
            self.state = .ready
            self.progress = 0.0
            return
        }

        switch task.state {
        case .ready:
            self.state = .ready
            self.progress = 0.0
        case let .downloading(progressValue):
            self.state = .downloading
            self.progress = progressValue
        case .paused:
            self.state = .paused
        // Keep existing progress
        case .complete:
            self.state = .completed
            self.progress = 1.0
        case .cancelled:
            self.state = .ready
            self.progress = 0.0
        case .error:
            self.state = .error
            // Keep existing progress
        }
    }

    // MARK: - Download Actions

    func start() {
        guard let item = item else { return }

        // Check if we already have a download task for this item
        if let existingTask = downloadTask {
            downloadManager.download(task: existingTask)
        } else {
            // Create a new download task
            let taskID = downloadManager.startDownload(
                itemId: item.id!,
                mediaSourceId: mediaSourceId
            )
            self.taskID = taskID
        }
    }

    func pause() {
        guard let taskID = taskID else { return }
        downloadManager.pauseDownload(taskID: taskID)
    }

    func resume() {
        guard let taskID = taskID else { return }
        downloadManager.resumeDownload(taskID: taskID)
    }

    func cancel() {
        guard let taskID = taskID else { return }
        downloadManager.cancelDownload(taskID: taskID, removeFile: true)
    }
}
