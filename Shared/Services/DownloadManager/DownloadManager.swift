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

final class DownloadManager: NSObject, ObservableObject {

    /// Background `URLSession` completion handlers stashed here by the
    /// platform's `UIApplicationDelegate` when iOS wakes the app to deliver
    /// finished-download events. The matching delegate callback below drains
    /// this dict so iOS can re-suspend us.
    static var backgroundCompletionHandlers: [String: () -> Void] = [:]

    let logger = Logger.swiftfin()

    @Injected(\.currentUserSession)
    var userSession: UserSession?

    @Published
    private(set) var records: [DownloadRecord] = []

    @Published
    private(set) var completedItems: [DownloadItemDto] = []

    private var queue: [String] = []
    var activeRecordID: String?
    var activeURLTasks: [String: URLSessionDownloadTask] = [:]
    private var lastPersistTime: [String: Date] = [:]

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

    // MARK: - Public API

    func record(id: String) -> DownloadRecord? {
        records.first { $0.id == id }
    }

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
                try await createMediaRecord(item)
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
        guard activeRecordID == id, let urlTask = activeURLTasks[id] else { return }

        urlTask.cancel { [weak self] resumeData in
            DispatchQueue.main.async {
                self?.handlePause(id: id, resumeData: resumeData)
            }
        }
    }

    private func handlePause(id: String, resumeData: Data?) {
        activeURLTasks.removeValue(forKey: id)
        if activeRecordID == id { activeRecordID = nil }

        update(id: id) { record in
            record.resumeData = resumeData
            record.state = .paused
        }

        advanceQueue()
    }

    func resume(id: String) {
        guard let record = record(id: id) else { return }
        guard record.state == .paused || record.state == .error else { return }

        update(id: id) { record in
            record.state = .queued
        }

        if !queue.contains(id) {
            queue.append(id)
        }

        advanceQueue()
    }

    /// Cancelling a download is functionally the same as deleting it — the
    /// record is removed and any in-flight transfer torn down. To restart,
    /// queue the item fresh.
    func cancel(id: String) {
        delete(id: id)
    }

    func retry(id: String) {
        resume(id: id)
    }

    /// Removes the record and all of its on-disk files.
    func delete(id: String) {
        if activeRecordID == id, let urlTask = activeURLTasks[id] {
            urlTask.cancel()
            activeURLTasks.removeValue(forKey: id)
            activeRecordID = nil
        }
        queue.removeAll(where: { $0 == id })

        guard let record = record(id: id) else { return }

        try? FileManager.default.removeItem(at: record.downloadFolder)

        records.removeAll(where: { $0.id == id })

        persistRecords()
        refreshCompletedItems()
        advanceQueue()
    }

    // MARK: - Queue management

    func advanceQueue() {
        guard activeRecordID == nil else { return }

        let nextID = records
            .filter { $0.state == .queued }
            .sorted { $0.createdAt < $1.createdAt }
            .first?
            .id

        guard let nextID else { return }
        startMediaDownload(id: nextID)
    }

    private func startMediaDownload(id: String) {
        guard let record = record(id: id) else { return }
        guard let userSession else { return }

        if let shortage = spaceShortage(for: record) {
            let formatter = ByteCountFormatter()
            formatter.countStyle = .file
            let need = formatter.string(fromByteCount: shortage.needed)
            let have = formatter.string(fromByteCount: shortage.available)
            logger.warning("Refusing to start \(id): need \(need) free, only \(have) available.")
            update(id: id) { rec in
                rec.state = .error
            }
            advanceQueue()
            return
        }

        activeRecordID = id

        update(id: id) { record in
            record.state = .downloading
        }

        let urlTask: URLSessionDownloadTask
        do {
            if let resumeData = record.resumeData {
                urlTask = urlSession.downloadTask(withResumeData: resumeData)
            } else {
                urlTask = try startRawDownload(id: id, userSession: userSession)
            }
        } catch {
            logger.error("Failed to start download \(id): \(error.localizedDescription)")
            activeRecordID = nil
            update(id: id) { rec in
                rec.state = .error
            }
            advanceQueue()
            return
        }

        urlTask.taskDescription = id
        activeURLTasks[id] = urlTask
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

    /// Returns `nil` if the device has enough free space for `record`'s
    /// projected on-disk footprint, otherwise the (needed, available) pair so
    /// the caller can compose a user-facing error.
    private func spaceShortage(for record: DownloadRecord) -> (needed: Int64, available: Int64)? {
        guard let item = record.item,
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
            records = []
            completedItems = []
            return
        }

        let loaded = StoredValues[.Downloads.items(userID: userID)]
        records = loaded

        let resurrected = records.map { record -> DownloadRecord in
            if record.state == .downloading {
                var mutable = record
                mutable.state = .paused
                return mutable
            }
            return record
        }

        if resurrected != records {
            records = resurrected
            persistRecords()
        }

        refreshCompletedItems()
    }

    private func persistRecords() {
        guard let userID = currentUserID else { return }
        StoredValues[.Downloads.items(userID: userID)] = records
    }

    func refreshCompletedItems() {
        completedItems = records
            .filter { $0.state == .complete }
            .compactMap { DownloadItemDto(record: $0, manager: self) }
    }

    /// Mutates the named record in-place and triggers a publish + persist.
    /// Throttles persistence during active downloads so high-frequency progress
    /// updates don't hammer the store.
    func update(id: String, throttlePersist: Bool = false, _ mutator: (inout DownloadRecord) -> Void) {
        guard let index = records.firstIndex(where: { $0.id == id }) else { return }
        var record = records[index]
        mutator(&record)
        record.updatedAt = Date()
        records[index] = record

        if throttlePersist {
            let now = Date()
            let last = lastPersistTime[id] ?? .distantPast
            if now.timeIntervalSince(last) > 1.0 {
                lastPersistTime[id] = now
                persistRecords()
            }
        } else {
            lastPersistTime[id] = Date()
            persistRecords()
        }
    }

    // MARK: - Record creation

    private func createMediaRecord(_ item: BaseItemDto) async throws {
        guard let id = item.id else { return }
        if record(id: id) != nil { return }

        let record = try DownloadRecord(item: item)

        await MainActor.run {
            records.append(record)
            persistRecords()
        }

        try await writeMetadataSidecar(item: item, in: record.downloadFolder)
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
