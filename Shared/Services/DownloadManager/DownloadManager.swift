//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Factory
import Foundation
import JellyfinAPI
import Logging
import UIKit

extension Container {
    var downloadManager: Factory<DownloadManager> {
        self { DownloadManager() }.shared
    }
}

/// Combined download status for a single library item.
enum ItemDownloadState: Hashable {
    case none
    case active(DownloadTask)
    case downloaded(DownloadItem)
}

final class DownloadManager: NSObject, ObservableObject {

    /// Background `URLSession` completion handlers stashed here by the
    /// platform's `UIApplicationDelegate` when iOS wakes the app to deliver
    /// finished-download events. The matching delegate callback below drains
    /// this dict so iOS can re-suspend us.
    static var backgroundCompletionHandlers: [String: () -> Void] = [:]

    let logger = Logger.swiftfin()

    @Injected(\.currentUserSession)
    var userSession: UserSession?

    /// In-flight downloads: queued, downloading, paused, or errored.
    /// A task graduates out of this array into `downloads` once finalized.
    @Published
    private(set) var tasks: [DownloadTask] = []

    /// Completed downloads. Persisted independently from `tasks`.
    @Published
    private(set) var downloads: [DownloadItem] = []

    var activeTaskID: String?
    var activeURLTask: URLSessionDownloadTask?
    private var lastPersistAt: Date?

    lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: "org.jellyfin.swiftfin.downloads")
        config.isDiscretionary = false
        config.sessionSendsLaunchEvents = true
        return URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue())
    }()

    private var currentUserID: String? {
        userSession?.user.id
    }

    override init() {
        super.init()
        rebuildFromStore()
        cleanStaging()
        _ = urlSession
        Task { @MainActor in
            self.advanceQueue()
        }
    }

    // MARK: - Public lookup

    func task(id: String) -> DownloadTask? {
        tasks.first { $0.id == id }
    }

    func download(id: String) -> DownloadItem? {
        downloads.first { $0.id == id }
    }

    func state(forItemID itemID: String) -> ItemDownloadState {
        if let task = task(id: itemID) {
            return .active(task)
        }
        if let download = download(id: itemID) {
            return .downloaded(download)
        }
        return .none
    }

    /// Combined publisher that emits the current `ItemDownloadState` for the
    /// given item whenever the *shape* of its state changes — i.e. the item
    /// moves between none / active / downloaded, or the active task's state
    /// case changes (queued ↔ downloading ↔ paused ↔ error).
    ///
    /// Progress updates (`bytesDownloaded`) deliberately do **not** trigger
    /// this publisher. UI that needs live progress reads `task(id:)?.progress`
    /// directly inside a `TimelineView`; firing on every byte tick would
    /// rebuild any subscribed `Menu` 10× per second and make taps unreliable.
    func statePublisher(for itemID: String) -> AnyPublisher<ItemDownloadState, Never> {
        Publishers.CombineLatest($tasks, $downloads)
            .map { tasks, downloads in
                if let task = tasks.first(where: { $0.id == itemID }) {
                    return .active(task)
                }
                if let download = downloads.first(where: { $0.id == itemID }) {
                    return .downloaded(download)
                }
                return .none
            }
            .removeDuplicates(by: { lhs, rhs in
                switch (lhs, rhs) {
                case (.none, .none):
                    true
                case let (.active(l), .active(r)):
                    l.state == r.state
                case let (.downloaded(l), .downloaded(r)):
                    l.id == r.id
                default:
                    false
                }
            })
            .eraseToAnyPublisher()
    }

    // MARK: - Public API

    /// Queues `item` (and, for containers, all of its downloadable children)
    /// for download.
    func queue(_ item: BaseItemDto) {
        Task { await queueAsync(item) }
    }

    private func queueAsync(_ item: BaseItemDto) async {
        guard currentUserID != nil else { return }
        guard let kind = item.type else { return }

        do {
            switch kind {
            case .movie, .episode:
                try await createMediaTask(item)
            case .season:
                let episodes = try await fetchSeasonEpisodes(seasonID: item.id!)
                for episode in episodes {
                    await queueAsync(episode)
                }
            case .series:
                let seasons = try await fetchSeasons(seriesID: item.id!)
                for season in seasons {
                    await queueAsync(season)
                }
            case .boxSet:
                let children = try await fetchBoxSetChildren(boxSetID: item.id!)
                for child in children {
                    await queueAsync(child)
                }
            default:
                return
            }
        } catch {
            logger.error("Failed to queue \(item.displayTitle): \(error.localizedDescription)")
        }

        await MainActor.run {
            advanceQueue()
        }
    }

    func pause(id: String) {
        guard activeTaskID == id, let urlTask = activeURLTask else { return }

        urlTask.cancel { [weak self] resumeData in
            DispatchQueue.main.async {
                self?.handlePause(id: id, resumeData: resumeData)
            }
        }
    }

    private func handlePause(id: String, resumeData: Data?) {
        activeURLTask = nil
        if activeTaskID == id { activeTaskID = nil }

        update(id: id) { task in
            task.resumeData = resumeData
            task.state = .paused
        }

        advanceQueue()
    }

    func resume(id: String) {
        guard let task = task(id: id) else { return }
        switch task.state {
        case .paused, .error:
            break
        default:
            return
        }

        update(id: id) { task in
            task.state = .queued
        }

        advanceQueue()
    }

    /// Cancelling an in-flight download is functionally the same as deleting
    /// it — the task is removed and any in-flight transfer torn down. To
    /// restart, queue the item fresh.
    func cancel(id: String) {
        delete(id: id)
    }

    func retry(id: String) {
        resume(id: id)
    }

    /// Removes the in-flight task or completed download (whichever the id
    /// matches) and all of its on-disk files.
    func delete(id: String) {
        if activeTaskID == id, let urlTask = activeURLTask {
            urlTask.cancel()
            activeURLTask = nil
            activeTaskID = nil
        }

        let folder: URL? = task(id: id)?.downloadFolder ?? download(id: id)?.downloadFolder
        if let folder {
            try? FileManager.default.removeItem(at: folder)
        }

        let removedTask = tasks.contains { $0.id == id }
        let removedDownload = downloads.contains { $0.id == id }

        tasks.removeAll(where: { $0.id == id })
        downloads.removeAll(where: { $0.id == id })

        if removedTask { persistTasks() }
        if removedDownload { persistDownloads() }

        advanceQueue()
    }

    // MARK: - Queue management

    func advanceQueue() {
        guard activeTaskID == nil else { return }

        let nextID = tasks
            .filter { $0.state == .queued }
            .sorted { $0.createdAt < $1.createdAt }
            .first?
            .id

        guard let nextID else { return }
        startMediaDownload(id: nextID)
    }

    private func startMediaDownload(id: String) {
        guard let task = task(id: id) else { return }
        guard let userSession else { return }

        if let shortage = spaceShortage(for: task) {
            let formatter = ByteCountFormatter()
            formatter.countStyle = .file
            let need = formatter.string(fromByteCount: shortage.needed)
            let have = formatter.string(fromByteCount: shortage.available)
            logger.warning("Refusing to start \(id): need \(need) free, only \(have) available.")
            update(id: id) { task in
                task.state = .error(.insufficientStorage)
            }
            advanceQueue()
            return
        }

        activeTaskID = id

        update(id: id) { task in
            task.state = .downloading
        }

        let urlTask: URLSessionDownloadTask
        do {
            urlTask = try task.makeURLSessionTask(in: urlSession, userSession: userSession)
        } catch {
            logger.error("Failed to start download \(id): \(error.localizedDescription)")
            activeTaskID = nil
            update(id: id) { task in
                task.state = .error(DownloadError(error))
            }
            advanceQueue()
            return
        }

        activeURLTask = urlTask
        urlTask.resume()
    }

    /// Whether the device has enough free space to download `item`. Budgets
    /// at 105% of source size. Returns `true` when source size is unknown or
    /// the volume can't be queried so the toolbar button doesn't get stuck
    /// disabled on missing telemetry.
    func canDownload(_ item: BaseItemDto) -> Bool {
        guard let sourceSize = item.mediaSources?.first?.size, sourceSize > 0 else { return true }
        let needed = Int64(Double(sourceSize) * 1.05)
        return spaceShortage(needed: needed) == nil
    }

    /// Returns `nil` if the device has enough free space for `task`'s
    /// projected on-disk footprint, otherwise the (needed, available) pair so
    /// the caller can compose a user-facing error.
    private func spaceShortage(for task: DownloadTask) -> (needed: Int64, available: Int64)? {
        guard let item = task.item,
              let sourceSize = item.mediaSources?.first?.size, sourceSize > 0
        else { return nil }

        let needed = Int64(Double(sourceSize) * 1.05)
        return spaceShortage(needed: needed)
    }

    private func spaceShortage(needed: Int64) -> (needed: Int64, available: Int64)? {
        guard let available = availableDiskBytes() else { return nil }
        return available >= needed ? nil : (needed, available)
    }

    private func availableDiskBytes() -> Int64? {
        do {
            let values = try URL.swiftfinDownloads
                .resourceValues(forKeys: [.volumeAvailableCapacityKey])
            return values.volumeAvailableCapacity.map(Int64.init)
        } catch {
            return nil
        }
    }

    // MARK: - Persistence

    private func rebuildFromStore() {
        guard let userID = currentUserID else {
            tasks = []
            downloads = []
            return
        }

        tasks = StoredValues[.Downloads.tasks(userID: userID)]
        downloads = StoredValues[.Downloads.items(userID: userID)]

        // App was killed mid-transfer — downgrade any `.downloading` task to
        // `.paused` so it can resume on the next user action.
        let resurrected = tasks.map { task -> DownloadTask in
            if task.state == .downloading {
                var mutable = task
                mutable.state = .paused
                return mutable
            }
            return task
        }

        if resurrected != tasks {
            tasks = resurrected
            persistTasks()
        }
    }

    private func persistTasks() {
        guard let userID = currentUserID else { return }
        StoredValues[.Downloads.tasks(userID: userID)] = tasks
    }

    private func persistDownloads() {
        guard let userID = currentUserID else { return }
        StoredValues[.Downloads.items(userID: userID)] = downloads
    }

    /// Mutates the named task in-place and triggers a publish + persist.
    /// Throttles persistence during active downloads so high-frequency
    /// progress updates don't hammer the store.
    func update(id: String, throttlePersist: Bool = false, _ mutator: (inout DownloadTask) -> Void) {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        var task = tasks[index]
        mutator(&task)
        task.updatedAt = Date()
        tasks[index] = task

        let now = Date()
        if throttlePersist {
            if now.timeIntervalSince(lastPersistAt ?? .distantPast) > 1.0 {
                lastPersistAt = now
                persistTasks()
            }
        } else {
            lastPersistAt = now
            persistTasks()
        }
    }

    // MARK: - Graduation

    /// Promotes a finished `DownloadTask` to a persisted `DownloadItem` and
    /// removes it from the in-flight task list. Called by the delegate's
    /// async finalize chain once the media file, images, subtitles and
    /// metadata sidecar are written to disk.
    func graduate(taskID: String, mediaRelativePath: String, images: [DownloadImage]) {
        guard let index = tasks.firstIndex(where: { $0.id == taskID }) else { return }
        let task = tasks[index]
        guard let item = task.item else {
            logger.error("Cannot graduate \(taskID): item JSON failed to decode")
            update(id: taskID) { $0.state = .error(.unknown("Failed to read item metadata")) }
            return
        }

        let download = DownloadItem(
            id: task.id,
            item: item,
            mediaRelativePath: mediaRelativePath,
            images: images,
            completedAt: Date()
        )

        tasks.remove(at: index)
        downloads.removeAll(where: { $0.id == task.id })
        downloads.append(download)

        persistTasks()
        persistDownloads()
    }

    // MARK: - Task creation

    private func createMediaTask(_ item: BaseItemDto) async throws {
        guard let id = item.id else { return }
        if task(id: id) != nil || download(id: id) != nil { return }

        let task = try DownloadTask(item: item)

        await MainActor.run {
            tasks.append(task)
            persistTasks()
        }
    }

    // MARK: - On-disk helpers

    func cleanStaging() {
        let staging = URL.swiftfinDownloads.appendingPathComponent(".staging", isDirectory: true)
        try? FileManager.default.removeItem(at: staging)
    }

    // MARK: - JellyfinAPI helpers

    private func fetchSeasons(seriesID: String) async throws -> [BaseItemDto] {
        guard let userSession else { throw URLError(.userAuthenticationRequired) }
        var parameters = Paths.GetSeasonsParameters()
        parameters.userID = userSession.user.id
        parameters.fields = .MinimumFields
        let request = Paths.getSeasons(seriesID: seriesID, parameters: parameters)
        let response = try await userSession.client.send(request)
        return response.value.items ?? []
    }

    private func fetchSeasonEpisodes(seasonID: String) async throws -> [BaseItemDto] {
        guard let userSession else { throw URLError(.userAuthenticationRequired) }
        var parameters = Paths.GetItemsParameters()
        parameters.userID = userSession.user.id
        parameters.parentID = seasonID
        parameters.includeItemTypes = [.episode]
        parameters.fields = .MinimumFields
        let request = Paths.getItems(parameters: parameters)
        let response = try await userSession.client.send(request)
        return response.value.items ?? []
    }

    private func fetchBoxSetChildren(boxSetID: String) async throws -> [BaseItemDto] {
        guard let userSession else { throw URLError(.userAuthenticationRequired) }
        var parameters = Paths.GetItemsParameters()
        parameters.userID = userSession.user.id
        parameters.parentID = boxSetID
        parameters.includeItemTypes = [.movie, .series, .episode]
        parameters.fields = .MinimumFields
        let request = Paths.getItems(parameters: parameters)
        let response = try await userSession.client.send(request)
        return response.value.items ?? []
    }
}
