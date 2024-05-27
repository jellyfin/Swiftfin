//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Factory
import Files
import Foundation
import JellyfinAPI

extension Container {

    static let downloadManager = Factory(scope: .singleton) {
        let manager = DownloadManager()
        manager.clearTmp()

        return manager
    }
}

class DownloadManager: ObservableObject {

    @Injected(LogManager.service)
    private var logger

    @Published
    private(set) var downloads: [DownloadEntity] = []

    // series and season shells
    private(set) var shellDownloads: [DownloadEntity] = []

    private var queue: [DownloadEntity] = []

    fileprivate init() {
        createDownloadDirectory()
        self.downloads = self.downloadedItems()
    }

    func eraseAllDownloads() {
        try? FileManager.default.removeItem(at: URL.downloads)
        createDownloadDirectory()
        self.downloads = []
    }

    private func createDownloadDirectory() {

        try? FileManager.default.createDirectory(
            at: URL.downloads,
            withIntermediateDirectories: true
        )
    }

    func clearTmp() {
        do {
            try Folder(path: URL.tmp.path).files.delete()

            logger.trace("Cleared tmp directory")
        } catch {
            logger.error("Unable to clear tmp directory: \(error.localizedDescription)")
        }
    }

    func download(task: DownloadEntity) {
        guard !downloads.contains(where: { $0.item == task.item }) else { return }
        guard !queue.contains(where: { $0.item == task.item }) else { return }

        queue.append(task)

        task.download()
    }

    func task(for item: BaseItemDto) -> DownloadEntity? {
        if let currentlyDownloading = downloads.first(where: { $0.item == item }) {
            return currentlyDownloading
        } else {
            var isDir: ObjCBool = true
            guard let downloadFolder = item.downloadFolder else { return nil }
            guard FileManager.default.fileExists(atPath: downloadFolder.path, isDirectory: &isDir) else { return nil }

            return parseDownloadItem(metaPath: downloadFolder.path)
        }
    }

    func cancel(task: DownloadEntity) {
        guard queue.contains(where: { $0.item == task.item }) else { return }

        task.cancel()

        remove(task: task)
    }

    func remove(task: DownloadEntity) {
        do {
            try FileManager.default.removeItem(at: task.item.downloadFolder!)
        } catch {
            logger.error("Error deleting item: \(error.localizedDescription)")
        }
        task.state = .ready
        queue.removeAll(where: { $0.item == task.item })
        downloads.removeAll(where: { $0.item == task.item })
    }

    func markReady(task: DownloadEntity) {
        guard queue.contains(where: { $0.item == task.item }) else { return }
        task.state = .complete

        queue.removeAll(where: { $0.item == task.item })
        downloads.append(task)
    }

    func getAdjacent(item: BaseItemDto) -> (DownloadEntity?, DownloadEntity?) {
        var previousEpisode: DownloadEntity?
        var nextEpisode: DownloadEntity?

        let seriesId = item.seriesID
        guard let seasonID = item.seasonID else { return (nil, nil) }

        guard let indexNumber = item.indexNumber else { return (nil, nil) }
        let indexNumberEnd = item.indexNumber ?? -1

        for download in downloads {
            if download.item.seriesID != seriesId {
                continue
            }
            if download.item.seasonID != seasonID {
                continue
            }

            guard let downloadIndexNumber = download.item.indexNumber else { continue }
            let downloadIndexNumberEnd = download.item.indexNumberEnd ?? -1
            if indexNumber - downloadIndexNumber == 1 || indexNumber - downloadIndexNumberEnd == 1 {
                previousEpisode = download
                continue
            }
            if indexNumber - downloadIndexNumber == -1 || indexNumberEnd - downloadIndexNumber == 1 {
                nextEpisode = download
                continue
            }
        }

        return (previousEpisode, nextEpisode)
    }

    func downloadedItems() -> [DownloadEntity] {
        do {
            let downloadContents = try FileManager.default.contentsOfDirectory(atPath: URL.downloads.path)
            var output: [DownloadEntity] = []
            for id in downloadContents {
                let contentFolder = URL.downloads.appendingPathComponent(id)
                let contents = parseDownloadFolder(path: contentFolder)
                output.append(contentsOf: contents)
            }
            return output
        } catch {
            logger.error("Error retrieving all downloads: \(error.localizedDescription)")

            return []
        }
    }

    private func parseDownloadFolder(path: URL) -> [DownloadEntity] {
        let movieMetadataFile = path.appendingPathComponent("Metadata").appendingPathComponent("Item.json")
        if FileManager.default.fileExists(atPath: movieMetadataFile.path) {
            let movieItem = parseDownloadItem(metaPath: movieMetadataFile.path)
            if movieItem != nil {
                return [movieItem!]
            }
        }

        var folderContent: [DownloadEntity] = []

        do {
            let seriesContents = try FileManager.default.contentsOfDirectory(atPath: path.path)
            for seasonID in seriesContents {
                let seasonPath = path.appendingPathComponent(seasonID)
                let seasonContent = try FileManager.default.contentsOfDirectory(atPath: seasonPath.path)
                for episodeID in seasonContent {
                    let episodePath = seasonPath.appendingPathComponent(episodeID)
                    guard let episodeItem = parseDownloadItem(
                        metaPath: episodePath.appendingPathComponent("Metadata")
                            .appendingPathComponent("Item.json").path
                    ) else { continue }
                    folderContent.append(episodeItem)
                }
            }
        } catch {
            return []
        }

        return folderContent
    }

    public func getItem(item: BaseItemDto) -> DownloadEntity? {
        if let mediaItem = (downloads.first { download in download.item.id == item.id }) {
            return mediaItem
        }

        guard let shellItem = (shellDownloads.first { shell in shell.item.id == item.id }) else { return nil }
        return shellItem
    }

    private func parseDownloadItem(metaPath: String) -> DownloadEntity? {
        guard let itemMetadataData = FileManager.default.contents(atPath: metaPath) else { return nil }

        let jsonDecoder = JSONDecoder()

        guard let offlineItem = try? jsonDecoder.decode(BaseItemDto.self, from: itemMetadataData) else { return nil }

        let task = DownloadEntity(item: offlineItem)
        if offlineItem.type != .episode && offlineItem.type != .movie || offlineItem.mediaSources == nil {
            // TODO: do this in any other way (this is really hacky)
            shellDownloads.append(DownloadEntity(item: offlineItem))
            return nil
        }
        task.expectedSize = Int64(offlineItem.mediaSources!.first!.size!)
        task.state = .complete
        return task
    }
}
