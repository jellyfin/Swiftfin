//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import FactoryKit
import Foundation
import JellyfinAPI
import Logging
import UIKit

extension Container {
    var downloadManager: Factory<DownloadManager> {
        self { MainActor.assumeIsolated { DownloadManager() } }.shared
    }
}

@MainActor
final class DownloadManager: NSObject, ObservableObject {

    struct Active {
        let id: String
        let urlTask: URLSessionDownloadTask
    }

    let logger = Logger.swiftfin()

    @Published
    var tasks: [DownloadTask] = []

    var active: Active?
    private var lastPersistedAt: Date?
    private var runningContainers: Set<String> = []

    lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: "org.jellyfin.swiftfin.downloads")
        config.isDiscretionary = false
        config.sessionSendsLaunchEvents = false
        return URLSession(configuration: config, delegate: self, delegateQueue: .main)
    }()

    var userSession: UserSession? {
        Container.shared.currentUserSession()
    }

    var currentUserID: String? {
        userSession?.user.id
    }

    override init() {
        super.init()
        load()
        _ = urlSession
        Task { @MainActor in
            self.advanceQueue()
        }
    }

    static let libraryID = "downloads"

    // MARK: - Lookup

    func task(id: String) -> DownloadTask? {
        tasks.first { $0.id == id }
    }

    func allItems() -> [BaseItemDto] {
        tasks.map(\.item)
    }

    func localQueryFilters() -> QueryFiltersLegacy {
        let completed = tasks.filter(\.isCompleted)

        let genres = Set(completed.compactMap(\.item.genres).flatMap(\.self))
        let tags = Set(completed.compactMap(\.item.tags).flatMap(\.self))
        let years = Set(completed.compactMap(\.item.productionYear))

        return QueryFiltersLegacy(
            genres: genres.sorted(),
            tags: tags.sorted(),
            years: years.sorted()
        )
    }

    func children(of id: String) -> [DownloadTask] {
        tasks.filter { $0.parentIDs.contains(id) }
    }

    func childItems(of id: String) -> [BaseItemDto] {
        children(of: id)
            .sorted { lhs, rhs in
                (lhs.item.indexNumber ?? .max, lhs.displayTitle) < (rhs.item.indexNumber ?? .max, rhs.displayTitle)
            }
            .map(\.item)
    }

    func topLevel() -> [DownloadTask] {
        let existingIDs = Set(tasks.map(\.id))
        return tasks.filter { task in
            !task.parentIDs.contains { existingIDs.contains($0) }
        }
    }

    func isFullyCompleted(_ task: DownloadTask) -> Bool {
        guard task.isCompleted else { return false }
        return descendants(of: task.id).allSatisfy { id in
            tasks.first(where: { $0.id == id })?.isCompleted ?? true
        }
    }

    func taskPublisher(for id: String) -> AnyPublisher<DownloadTask?, Never> {
        $tasks
            .map { $0.first(where: { $0.id == id }) }
            .removeDuplicates(by: { $0?.state == $1?.state })
            .eraseToAnyPublisher()
    }

    func descendants(of id: String) -> [String] {
        var result: [String] = []
        var queue = children(of: id).map(\.id)
        while let next = queue.popLast() {
            result.append(next)
            queue.append(contentsOf: children(of: next).map(\.id))
        }
        return result
    }

    // MARK: - Lifecycle

    func pause(id: String) {
        guard let active, active.id == id else { return }
        let urlTask = active.urlTask

        urlTask.cancel { [weak self] resumeData in
            Task { @MainActor in
                self?.handlePause(id: id, resumeData: resumeData)
            }
        }
    }

    private func handlePause(id: String, resumeData: Data?) {
        if active?.id == id { active = nil }

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

    func delete(id: String) {
        let ids = [id] + descendants(of: id)
        for taskID in ids {
            deleteOne(id: taskID)
        }
        pruneEmptyContainers()
        refreshContainerUnplayedCounts()
        advanceQueue()
    }

    private func pruneEmptyContainers() {
        while true {
            let empty = tasks.filter { $0.isContainer && $0.isCompleted && children(of: $0.id).isEmpty }
            guard empty.isNotEmpty else { break }

            for task in empty {
                deleteOne(id: task.id)
            }
        }
    }

    private func deleteOne(id: String) {
        if let active, active.id == id {
            active.urlTask.cancel()
            self.active = nil
        }

        runningContainers.remove(id)

        let folder = task(id: id)?.downloadFolder
        let removed = tasks.contains { $0.id == id }
        tasks.removeAll(where: { $0.id == id })

        if removed { persistTasks() }

        if let folder {
            Task.detached(priority: .utility) {
                try? FileManager.default.removeItem(at: folder)
            }
        }
    }

    // MARK: - Queue advancement

    func advanceQueue() {
        advanceContainers()
        advanceMedia()
    }

    private func advanceMedia() {
        guard active == nil else { return }

        let nextID = tasks
            .filter {
                if case .media = $0.kind, $0.state == .queued { return true }
                return false
            }
            .sorted { $0.createdAt < $1.createdAt }
            .first?
            .id

        guard let nextID else { return }
        startMediaDownload(id: nextID)
    }

    private func advanceContainers() {
        let queued = tasks.filter {
            $0.isContainer && $0.state == .queued && !runningContainers.contains($0.id)
        }
        for task in queued {
            startContainerDownload(id: task.id)
        }
    }

    private func startMediaDownload(id: String) {
        guard let task = task(id: id) else { return }
        guard let userSession else { return }

        if let shortage = spaceShortage(for: task) {
            let need = shortage.needed.formatted(.byteCount(style: .file))
            let have = shortage.available.formatted(.byteCount(style: .file))
            logger.warning("Refusing to start \(id): need \(need) free, only \(have) available.")
            update(id: id) { task in
                task.state = .error(.insufficientStorage)
            }
            advanceQueue()
            return
        }

        update(id: id) { task in
            task.state = .downloading
        }

        let urlTask: URLSessionDownloadTask
        do {
            urlTask = try task.makeURLSessionTask(in: urlSession, userSession: userSession)
        } catch {
            logger.error("Failed to start download \(id): \(error.localizedDescription)")
            update(id: id) { task in
                task.state = .error(DownloadError(error))
            }
            advanceQueue()
            return
        }

        active = Active(id: id, urlTask: urlTask)
        urlTask.resume()
    }

    private func startContainerDownload(id: String) {
        guard let task = task(id: id) else { return }

        runningContainers.insert(id)
        update(id: id) { $0.state = .downloading }

        let snapshot = task
        Task {
            await snapshot.downloadImages(item: snapshot.item)
            await MainActor.run {
                self.runningContainers.remove(id)
                self.complete(id: id, mediaRelativePath: nil)
            }
        }
    }

    // MARK: - Disk budget

    func hasSpace(for item: BaseItemDto) -> Bool {
        guard let sourceSize = item.mediaSources?.first?.size, sourceSize > 0 else { return true }
        let needed = Int64(Double(sourceSize) * 1.05)
        return spaceShortage(needed: needed) == nil
    }

    private func spaceShortage(for task: DownloadTask) -> (needed: Int64, available: Int64)? {
        guard let sourceSize = task.item.mediaSources?.first?.size, sourceSize > 0 else { return nil }
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

    private func load() {
        guard let userID = currentUserID else {
            tasks = []
            return
        }

        let stored = StoredValues[.Downloads.all(userID: userID)]

        let resurrected = stored.map { task -> DownloadTask in
            guard task.state == .downloading else { return task }
            // Media tasks may hold resume data, so pause instead of requeueing
            return task.mutating(\.state, with: task.isContainer ? .queued : .paused)
        }

        tasks = resurrected
        if resurrected != stored {
            persistTasks()
        }

        refreshContainerUnplayedCounts()
    }

    func persistTasks() {
        guard let userID = currentUserID else { return }
        StoredValues[.Downloads.all(userID: userID)] = tasks
    }

    func update(id: String, throttle: Bool = false, _ mutator: (inout DownloadTask) -> Void) {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        var task = tasks[index]
        mutator(&task)
        tasks[index] = task

        let now = Date()
        if throttle {
            if now.timeIntervalSince(lastPersistedAt ?? .distantPast) > 1.0 {
                lastPersistedAt = now
                persistTasks()
            }
        } else {
            lastPersistedAt = now
            persistTasks()
        }
    }

    // MARK: - User data

    func setIsPlayed(_ isPlayed: Bool, for id: String) -> UserItemDataDto? {
        guard let task = task(id: id) else { return nil }

        if task.isContainer {
            for media in downloadedEpisodes(under: id) {
                setUserData(for: media.id) { userData in
                    userData.isPlayed = isPlayed
                    userData.playbackPositionTicks = 0
                    userData.playedPercentage = nil
                }
            }
        }

        let result = setUserData(for: id) { userData in
            userData.isPlayed = isPlayed

            if isPlayed {
                userData.playbackPositionTicks = 0
                userData.playedPercentage = nil
            }
        }

        refreshContainerUnplayedCounts()

        return result
    }

    func setIsFavorite(_ isFavorite: Bool, for id: String) -> UserItemDataDto? {
        setUserData(for: id) { $0.isFavorite = isFavorite }
    }

    @discardableResult
    private func setUserData(
        for id: String,
        notify: Bool = true,
        _ mutator: (inout UserItemDataDto) -> Void
    ) -> UserItemDataDto? {
        guard task(id: id) != nil else { return nil }

        update(id: id) { task in
            var userData = task.item.userData ?? UserItemDataDto()
            userData.itemID = id
            mutator(&userData)
            task.item.userData = userData
        }

        guard let userData = task(id: id)?.item.userData else { return nil }

        if notify {
            Notifications[.itemUserDataDidChange].post(userData)
        }

        return userData
    }

    func refreshContainerUnplayedCounts() {
        for container in tasks.filter(\.isContainer) {
            let media = downloadedEpisodes(under: container.id)
            let unplayedCount = media.count(where: { $0.item.userData?.isPlayed != true })
            let isPlayed = media.isNotEmpty && unplayedCount == 0

            let current = container.item.userData
            guard current?.unplayedItemCount != unplayedCount || (current?.isPlayed ?? false) != isPlayed else { continue }

            setUserData(for: container.id) { userData in
                userData.unplayedItemCount = unplayedCount
                userData.isPlayed = isPlayed
            }
        }
    }

    // MARK: - Playback session

    private func playbackRuntime(for id: String) -> Int? {
        guard let item = task(id: id)?.item else { return nil }
        return item.runTimeTicks ?? item.mediaSources?.first?.runTimeTicks
    }

    func reportPlaybackProgress(for id: String, seconds: Duration?) {
        guard let ticks = seconds?.ticks else { return }
        let runtime = playbackRuntime(for: id)

        setUserData(for: id, notify: false) { userData in
            userData.playbackPositionTicks = ticks

            if let runtime, runtime > 0 {
                userData.playedPercentage = Double(ticks) / Double(runtime) * 100
            }
        }
    }

    func reportPlaybackStopped(for id: String, seconds: Duration?) {
        guard let ticks = seconds?.ticks else { return }
        let runtime = playbackRuntime(for: id)

        setUserData(for: id) { userData in
            if let runtime, runtime > 0, Double(ticks) / Double(runtime) >= 0.9 {
                userData.isPlayed = true
                userData.playbackPositionTicks = 0
                userData.playedPercentage = nil
            } else {
                userData.playbackPositionTicks = ticks

                if let runtime, runtime > 0 {
                    userData.playedPercentage = Double(ticks) / Double(runtime) * 100
                }
            }
        }

        refreshContainerUnplayedCounts()
    }

    // MARK: - Completion

    func complete(id: String, mediaRelativePath: String?) {
        update(id: id) { task in
            task.state = .completed(mediaRelativePath: mediaRelativePath)
            task.resumeData = nil
        }
        refreshContainerUnplayedCounts()
        advanceQueue()
    }
}
