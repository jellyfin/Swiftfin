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

extension DownloadTask {

    var trickplayFolder: URL {
        downloadFolder.appendingPathComponent("Trickplay", isDirectory: true)
    }

    private func trickplayInfo(for item: BaseItemDto) -> TrickplayInfoDto? {
        guard let mediaSourceID = item.mediaSources?.first?.id else { return nil }

        return item.trickplay?[mediaSourceID]?
            .values
            .sorted { ($0.width ?? 0) < ($1.width ?? 0) }
            .first
    }

    private func tileSheetCount(for info: TrickplayInfoDto) -> Int {
        let tilesPerSheet = (info.tileWidth ?? 0) * (info.tileHeight ?? 0)
        guard tilesPerSheet > 0, let thumbnailCount = info.thumbnailCount else { return 0 }
        return Int((Double(thumbnailCount) / Double(tilesPerSheet)).rounded(.up))
    }

    private func tileSheetURL(width: Int, index: Int) -> URL {
        trickplayFolder
            .appendingPathComponent("\(width)", isDirectory: true)
            .appendingPathComponent("\(index)")
    }

    func downloadTrickplay(item: BaseItemDto, userSession: UserSession) async {
        guard let itemID = item.id,
              let info = trickplayInfo(for: item),
              let width = info.width
        else { return }

        let sheetCount = tileSheetCount(for: info)
        guard sheetCount > 0 else { return }

        let folder = tileSheetURL(width: width, index: 0).deletingLastPathComponent()

        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        } catch {
            Logger.swiftfin().warning("Failed to create trickplay folder: \(error.localizedDescription)")
            return
        }

        for index in 0 ..< sheetCount {
            let request = Paths.getTrickplayTileImage(itemID: itemID, width: width, index: index)

            guard let response = try? await userSession.client.send(request) else { continue }

            let destination = tileSheetURL(width: width, index: index)
            try? FileManager.default.removeItem(at: destination)
            try? response.value.write(to: destination)
        }
    }

    func downloadedTrickplayPreviewImageProvider() -> TrickplayPreviewImageProvider? {
        guard case .trickplay = StoredValues[.User.previewImageScrubbing] else { return nil }

        guard let itemID = item.id,
              let mediaSourceID = item.mediaSources?.first?.id,
              let info = trickplayInfo(for: item),
              let width = info.width
        else { return nil }

        guard FileManager.default.fileExists(atPath: tileSheetURL(width: width, index: 0).path) else { return nil }

        let widthFolder = tileSheetURL(width: width, index: 0).deletingLastPathComponent()

        return TrickplayPreviewImageProvider(
            info: info,
            itemID: itemID,
            mediaSourceID: mediaSourceID,
            runtime: item.runtime ?? .zero
        ) { index in
            try? Data(contentsOf: widthFolder.appendingPathComponent("\(index)"))
        }
    }
}
