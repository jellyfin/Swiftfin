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
        self { MainActor.assumeIsolated { DownloadManager() } }.shared
    }
}

@MainActor
final class DownloadManager: NSObject, ObservableObject {

    struct Active {
        let id: String
        let urlTask: URLSessionDownloadTask
    }

    nonisolated(unsafe) static var backgroundCompletionHandlers: [String: () -> Void] = [:]

    let logger = Logger.swiftfin()

    @Injected(\.currentUserSession)
    var userSession: UserSession?

    @Published
    var tasks: [DownloadTask] = []

    var active: Active?
    private var lastPersistedAt: Date?

    lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: "org.jellyfin.swiftfin.downloads")
        config.isDiscretionary = false
        config.sessionSendsLaunchEvents = true
        return URLSession(configuration: config, delegate: self, delegateQueue: .main)
    }()

    var currentUserID: String? {
        userSession?.user.id
    }

    override init() {
        super.init()
        load()
        cleanStaging()
        _ = urlSession
        Task { @MainActor in
            self.advanceQueue()
        }
    }

    // MARK: - Lookup

    func task(id: String) -> DownloadTask? {
        tasks.first { $0.id == id }
    }

    func taskPublisher(for id: String) -> AnyPublisher<DownloadTask?, Never> {
        $tasks
            .map { $0.first(where: { $0.id == id }) }
            .removeDuplicates(by: { $0?.state == $1?.state })
            .eraseToAnyPublisher()
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

    func cancel(id: String) {
        delete(id: id)
    }

    func retry(id: String) {
        resume(id: id)
    }

    func delete(id: String) {
        if let active, active.id == id {
            active.urlTask.cancel()
            self.active = nil
        }

        let folder = task(id: id)?.downloadFolder
        let removed = tasks.contains { $0.id == id }
        tasks.removeAll(where: { $0.id == id })

        if removed { persistTasks() }

        if let folder {
            Task.detached(priority: .utility) {
                try? FileManager.default.removeItem(at: folder)
            }
        }

        advanceQueue()
    }

    // MARK: - Queue advancement

    func advanceQueue() {
        guard active == nil else { return }

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

    // MARK: - Disk budget

    func canDownload(_ item: BaseItemDto) -> Bool {
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

        let migrated = StoredValues.Keys.Downloads.loadAndMigrate(userID: userID)

        let resurrected = migrated.map { task -> DownloadTask in
            if task.state == .downloading {
                var mutable = task
                mutable.state = .paused
                return mutable
            }
            return task
        }

        tasks = resurrected
        if resurrected != migrated {
            persistTasks()
        }
    }

    func persistTasks() {
        guard let userID = currentUserID else { return }
        StoredValues[.Downloads.all(userID: userID)] = tasks
    }

    func update(id: String, throttle: Bool = false, _ mutator: (inout DownloadTask) -> Void) {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        var task = tasks[index]
        mutator(&task)
        task.updatedAt = Date()
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

    // MARK: - Completion

    func complete(id: String, mediaRelativePath: String, images: [DownloadImage]) {
        update(id: id) { task in
            task.state = .completed(
                completedAt: Date(),
                mediaRelativePath: mediaRelativePath,
                images: images
            )
            task.resumeData = nil
        }
    }

    // MARK: - On-disk helpers

    func cleanStaging() {
        let staging = URL.swiftfinDownloads.appendingPathComponent(".staging", isDirectory: true)
        Task.detached(priority: .utility) {
            try? FileManager.default.removeItem(at: staging)
        }
    }
}
