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
    private var taskStateObserver: AnyCancellable?
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
        // First, check if the item is already downloaded locally
        checkInitialDownloadState()

        // Observe downloads array for task creation/removal
        downloadManager.$downloads
            .debounce(for: .milliseconds(50), scheduler: DispatchQueue.main)
            .sink { [weak self] downloads in
                guard let self = self, let itemId = self.item?.id else { return }

                // Find our specific task in the downloads array by both item ID and media source ID
                let currentTask = downloads.first { task in
                    task.item.id == itemId && task.mediaSourceId == self.mediaSourceId
                }

                // Only update if task reference actually changed
                let taskChanged = (self.downloadTask?.taskID != currentTask?.taskID)

                if taskChanged {
                    // Update our references
                    self.downloadTask = currentTask
                    self.taskID = currentTask?.taskID

                    // Cancel existing task state observer
                    self.taskStateObserver?.cancel()
                    self.taskStateObserver = nil

                    // Set up new task state observer if we have a task
                    if let taskID = currentTask?.taskID {
                        self.observeTaskState(taskID: taskID)
                    }

                    // Update UI state
                    self.updateStateFromDownloadTask(currentTask)
                }
            }
            .store(in: &cancellables)
    }

    private func observeTaskState(taskID: UUID) {
        taskStateObserver = downloadManager.$taskStates
            .compactMap { $0[taskID] }
            .removeDuplicates { prev, curr in
                // Custom comparison for DownloadTask.State
                switch (prev, curr) {
                case let (.downloading(prevProgress), .downloading(currProgress)):
                    return abs(prevProgress - currProgress) < 0.05 // 5% threshold
                case (.ready, .ready), (.paused, .paused), (.complete, .complete), (.cancelled, .cancelled):
                    return true
                case (.error, .error):
                    return true // Don't duplicate error states
                default:
                    return false // Different states, should update
                }
            }
            .sink { [weak self] taskState in
                guard let self = self else { return }
                self.updateFromTaskState(taskState)
            }
    }

    private func updateFromTaskState(_ taskState: DownloadTask.State) {
        switch taskState {
        case .ready:
            if self.state != .ready {
                self.state = .ready
                self.progress = 0.0
            }
        case let .downloading(progressValue):
            let isStateTransition = self.state != .downloading
            let isSignificantProgressChange = abs(progressValue - self.progress) >= 0.05
            let isCompletion = progressValue == 1.0

            if isStateTransition || isSignificantProgressChange || isCompletion {
                self.state = .downloading
                self.progress = progressValue
            }
        case .paused:
            if self.state != .paused {
                self.state = .paused
            }
        case .complete:
            if self.state != .completed {
                self.state = .completed
                self.progress = 1.0
            }
        case .cancelled:
            if self.state != .ready {
                self.state = .ready
                self.progress = 0.0
            }
        case .error:
            if self.state != .error {
                self.state = .error
            }
        }
    }

    private func checkInitialDownloadState() {
        guard let item = item, let itemId = item.id else { return }

        // Check if this specific version is already downloaded
        if downloadManager.isItemVersionDownloaded(itemId: itemId, mediaSourceId: mediaSourceId) {
            self.state = .completed
            self.progress = 1.0
        }
    }

    private func updateStateFromDownloadTask(_ task: DownloadTask?) {
        guard let task = task else {
            // No active download task - check if item is downloaded locally only if we're not already in completed state
            if self.state != .completed,
               let item = item, let itemId = item.id,
               downloadManager.isItemVersionDownloaded(itemId: itemId, mediaSourceId: mediaSourceId)
            {
                self.state = .completed
                self.progress = 1.0
            } else if self.state != .ready && self.state != .completed {
                // Only reset to ready if we're not already ready or completed
                self.state = .ready
                self.progress = 0.0
            }
            return
        }

        let taskState = downloadManager.getTaskState(taskID: task.taskID)
        switch taskState {
        case .ready:
            if self.state != .ready {
                self.state = .ready
                self.progress = 0.0
            }
        case let .downloading(progressValue):
            // Always allow state transitions, but throttle progress updates within the same state
            let isStateTransition = self.state != .downloading
            let isSignificantProgressChange = abs(progressValue - self.progress) >= 0.05
            let isCompletion = progressValue == 1.0

            if isStateTransition || isSignificantProgressChange || isCompletion {
                self.state = .downloading
                self.progress = progressValue
            }
        case .paused:
            if self.state != .paused {
                self.state = .paused
                // Keep existing progress
            }
        case .complete:
            if self.state != .completed {
                self.state = .completed
                self.progress = 1.0
            }
        case .cancelled:
            if self.state != .ready {
                self.state = .ready
                self.progress = 0.0
            }
        case .error:
            if self.state != .error {
                self.state = .error
                // Keep existing progress
            }
        }
    }

    // MARK: - Download Actions

    func start() {
        guard let item = item, let itemId = item.id else { return }

        // Don't start download if version already downloaded
        if downloadManager.isItemVersionDownloaded(itemId: itemId, mediaSourceId: mediaSourceId) {
            return
        }

        // Always start via DownloadManager.startDownload to honor mediaSourceId
        let taskID = downloadManager.startDownload(
            itemId: itemId,
            mediaSourceId: mediaSourceId
        )
        self.taskID = taskID
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

    /// Manually refresh the download state - useful for debugging or when state might be stale
    func refreshDownloadState() {
        checkInitialDownloadState()
    }
}
