//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

extension DownloadManager {

    func cleanStaging() {
        let staging = URL.swiftfinDownloads.appendingPathComponent(".staging", isDirectory: true)
        try? FileManager.default.removeItem(at: staging)
    }

    func writeMetadataSidecar(item: BaseItemDto, in folder: URL) async throws {
        let metadataFolder = folder.appendingPathComponent("Metadata", isDirectory: true)
        try FileManager.default.createDirectory(at: metadataFolder, withIntermediateDirectories: true)

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(item)
        try data.write(to: metadataFolder.appendingPathComponent("Item.json"))
    }
}
