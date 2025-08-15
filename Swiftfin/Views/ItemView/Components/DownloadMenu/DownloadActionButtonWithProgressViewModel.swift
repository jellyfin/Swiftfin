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
    private var allTaskStateObservers: [UUID: AnyCancellable] = [:]
    private var downloadTask: DownloadTask?
    private var taskID: UUID?
    private var allItemTasks: [DownloadTask] = []

    private var shouldAutoStart: Bool = true

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
    init(item: BaseItemDto, mediaSourceId: String? = nil, shouldAutoStart: Bool = true) {
        self.item = item
        self.mediaSourceId = mediaSourceId
        self.shouldAutoStart = shouldAutoStart
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

                if let specificMediaSourceId = self.mediaSourceId {
                    // Specific version mode: Find task matching both item ID and specific media source ID
                    let currentTask = downloads.first { task in
                        task.item.id == itemId && task.mediaSourceId == specificMediaSourceId
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
                } else {
                    // All versions mode: Find ALL tasks for this item regardless of media source
                    let currentTasks = downloads.filter { task in
                        task.item.id == itemId
                    }

                    // Check if the set of tasks has changed
                    let currentTaskIDs = Set(currentTasks.map(\.taskID))
                    let previousTaskIDs = Set(self.allItemTasks.map(\.taskID))
                    let tasksChanged = currentTaskIDs != previousTaskIDs

                    if tasksChanged {
                        // Update our references
                        self.allItemTasks = currentTasks

                        // Cancel all existing task state observers
                        self.allTaskStateObservers.values.forEach { $0.cancel() }
                        self.allTaskStateObservers.removeAll()

                        // Set up observers for all current tasks
                        for task in currentTasks {
                            self.observeAllVersionsTaskState(taskID: task.taskID)
                        }

                        // Update UI state based on all tasks
                        self.updateStateFromAllTasks()
                    }
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

    private func observeAllVersionsTaskState(taskID: UUID) {
        let observer = downloadManager.$taskStates
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
            .sink { [weak self] _ in
                guard let self = self else { return }
                // When any task state changes, recalculate combined state
                self.updateStateFromAllTasks()
            }

        allTaskStateObservers[taskID] = observer
    }

    private func updateStateFromAllTasks() {
        guard let itemId = item?.id else { return }

        // Get current state of all tasks for this item
        let allTaskStates = allItemTasks.compactMap { task in
            downloadManager.getTaskState(taskID: task.taskID)
        }

        // Get total available versions and already downloaded versions
        let totalAvailableVersions = item?.mediaSources?.count ?? 1
        let alreadyDownloadedVersions = downloadManager.getDownloadedVersions(for: itemId).count

        print("TOTAL _ \(totalAvailableVersions) _ ALREADY _ \(alreadyDownloadedVersions)")
        print("ALL TASKS \(allTaskStates.count)")

        // If no active tasks, determine state based on downloaded versions
        if allTaskStates.isEmpty {
            if alreadyDownloadedVersions == totalAvailableVersions {
                self.state = .completed
                self.progress = 1.0
            } else if alreadyDownloadedVersions > 0 {
                self.state = .partiallyCompleted
                self.progress = Double(alreadyDownloadedVersions) / Double(totalAvailableVersions)
            } else {
                self.state = .ready
                self.progress = 0.0
            }
            return
        }

        // Calculate combined state from all active tasks
        let downloadingTasks = allTaskStates.compactMap { state -> Double? in
            if case let .downloading(progress) = state { return progress }
            return nil
        }

        let hasError = allTaskStates.contains { if case .error = $0 { return true }
            return false
        }
        let hasPaused = allTaskStates.contains { if case .paused = $0 { return true }
            return false
        }
        let activeCompletedCount = allTaskStates.filter { if case .complete = $0 { return true }
            return false
        }.count

        // Calculate total completed versions (active completed + already downloaded)
        let totalCompletedVersions = activeCompletedCount + alreadyDownloadedVersions

        // Determine combined state
        if !downloadingTasks.isEmpty {
            // At least one task is downloading
            self.state = .downloading
            self.progress = downloadingTasks.reduce(0, +) / Double(downloadingTasks.count) // Average progress
        } else if hasError {
            self.state = .error
        } else if hasPaused {
            self.state = .paused
        } else if totalCompletedVersions == totalAvailableVersions {
            // All versions are completed (active + already downloaded)
            self.state = .completed
            self.progress = 1.0
        } else if totalCompletedVersions > 0 {
            // Some versions are completed but not all
            self.state = .partiallyCompleted
            self.progress = Double(totalCompletedVersions) / Double(totalAvailableVersions)
        } else {
            self.state = .ready
            self.progress = 0.0
        }
    }

    private func checkInitialDownloadState() {
        guard let item = item, let itemId = item.id else { return }

        if self.shouldAutoStart {
            // Specific version mode: Check if this specific version is already downloaded
            if downloadManager.isItemVersionDownloaded(itemId: itemId, mediaSourceId: self.mediaSourceId) {
                self.state = .completed
                self.progress = 1.0
            }
        } else {
            // All versions mode: Check download status for all versions
            if downloadManager.isItemDownloaded(itemId: itemId) {
                let availableVersionsCount = item.mediaSources?.count ?? 1
                let downloadedVersionsCount = downloadManager.getDownloadedVersions(for: itemId).count

                if downloadedVersionsCount == availableVersionsCount {
                    self.state = .completed
                    self.progress = 1.0
                } else if downloadedVersionsCount > 0 && downloadedVersionsCount < availableVersionsCount {
                    self.state = .partiallyCompleted
                    self.progress = Double(downloadedVersionsCount) / Double(availableVersionsCount)
                }
            }
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

    deinit {
        // Cancel all observers
        taskStateObserver?.cancel()
        allTaskStateObservers.values.forEach { $0.cancel() }
        allTaskStateObservers.removeAll()
    }
}
