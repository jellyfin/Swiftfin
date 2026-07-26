//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import Logging

extension DownloadManager {

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
        cascadeDelete(id: id)
        pruneEmptyContainers()
        refreshContainerUnplayedCounts()
        advanceQueue()
    }

    private func cascadeDelete(id: String) {
        guard task(id: id) != nil else { return }

        let childTasks = children(of: id)
        deleteOne(id: id)

        for child in childTasks {
            let hasSurvivingParent = child.parentIDs.contains { $0 != id && task(id: $0) != nil }

            if !hasSurvivingParent {
                cascadeDelete(id: child.id)
            }
        }
    }

    func clearAll() {
        active?.urlTask.cancel()
        active = nil
        runningContainers.removeAll()

        tasks = []
        persistTasks()

        Task.detached(priority: .utility) {
            try? FileManager.default.removeItem(at: URL.swiftfinDownloads)
            try? FileManager.default.createDirectory(at: URL.swiftfinDownloads, withIntermediateDirectories: true)
        }
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

    // MARK: - Completion

    func complete(id: String, mediaRelativePath: String?) {
        update(id: id) { task in
            task.state = .completed(mediaRelativePath: mediaRelativePath)
            task.resumeData = nil
        }
        refreshContainerUnplayedCounts()
        advanceQueue()
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
}
