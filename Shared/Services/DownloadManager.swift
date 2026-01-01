//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Factory
import Files
import Foundation
import JellyfinAPI
import Logging

extension Container {
    var downloadManager: Factory<DownloadManager> { self { DownloadManager() }.shared }
}

class DownloadManager: ObservableObject {

    private let logger = Logger.swiftfin()

    @Published
    private(set) var downloads: [DownloadTask] = []

    fileprivate init() {

        createDownloadDirectory()
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

    func download(task: DownloadTask) {
        guard !downloads.contains(where: { $0.item == task.item }) else { return }

        downloads.append(task)

        task.download()
    }

    func task(for item: BaseItemDto) -> DownloadTask? {
        if let currentlyDownloading = downloads.first(where: { $0.item == item }) {
            return currentlyDownloading
        } else {
            var isDir: ObjCBool = true
            guard let downloadFolder = item.downloadFolder else { return nil }
            guard FileManager.default.fileExists(atPath: downloadFolder.path, isDirectory: &isDir) else { return nil }

            return parseDownloadItem(with: item.id!)
        }
    }

    func cancel(task: DownloadTask) {
        guard downloads.contains(where: { $0.item == task.item }) else { return }

        task.cancel()

        remove(task: task)
    }

    func remove(task: DownloadTask) {
        downloads.removeAll(where: { $0.item == task.item })
    }

    func downloadedItems() -> [DownloadTask] {
        do {
            let downloadContents = try FileManager.default.contentsOfDirectory(atPath: URL.downloads.path)
            return downloadContents.compactMap(parseDownloadItem(with:))
        } catch {
            logger.error("Error retrieving all downloads: \(error.localizedDescription)")

            return []
        }
    }

    private func parseDownloadItem(with id: String) -> DownloadTask? {

        let itemMetadataFile = URL.downloads
            .appendingPathComponent(id)
            .appendingPathComponent("Metadata")
            .appendingPathComponent("Item.json")

        guard let itemMetadataData = FileManager.default.contents(atPath: itemMetadataFile.path) else { return nil }

        let jsonDecoder = JSONDecoder()

        guard let offlineItem = try? jsonDecoder.decode(BaseItemDto.self, from: itemMetadataData) else { return nil }

        let task = DownloadTask(item: offlineItem)
        task.state = .complete
        return task
    }
}
