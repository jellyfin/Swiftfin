//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Files
import UIKit

@MainActor
final class PlaybackTemporaryFiles {

    private let accessToken: String?
    private let directoryPath = "playback/\(UUID().uuidString)"
    private let session: URLSession

    private var downloadURL: ((Int) -> URL?)?
    private var files: [Int: Task<URL?, Never>] = [:]
    private var latestImage: (id: Int, image: Task<UIImage?, Never>)?
    private var preloadTask: Task<Void, Never>?
    private var isRemoved = false

    init(accessToken: String?) {
        self.accessToken = accessToken

        let configuration = URLSessionConfiguration.ephemeral
        configuration.urlCache = nil
        configuration.timeoutIntervalForRequest = 20

        session = URLSession(configuration: configuration)
    }

    isolated deinit {
        remove()
    }

    /// Downloads the provider's images in order, one at a time, ahead of use.
    ///
    /// Stops at the first image that fails, since trickplay doesn't say how many sheets exist.
    func download(for provider: PreviewImageProvider) {
        guard !isRemoved, preloadTask == nil else { return }

        downloadURL = { [weak provider] id in provider?.downloadURL(for: id) }
        let ids = provider.downloadIDs

        preloadTask = Task(priority: .utility) { [weak self] in
            for id in ids {
                guard !Task.isCancelled, await self?.file(for: id) != nil else { return }
            }
        }
    }

    /// The decoded image for a download's ID. The latest image stays decoded for repeated lookups.
    func image(for id: Int) async -> UIImage? {
        let image: Task<UIImage?, Never>

        if let latestImage, latestImage.id == id {
            image = latestImage.image
        } else {
            image = Task { [weak self] in
                guard let file = await self?.file(for: id) else { return nil }

                return await UIImage(contentsOfFile: file.path)?.byPreparingForDisplay()
            }

            latestImage = (id, image)
        }

        let value = await image.value

        // Let a later lookup retry a failed image.
        if value == nil, latestImage?.id == id {
            latestImage = nil
        }

        return value
    }

    /// Downloads once and shares the result. Cancelling a caller doesn't cancel the download.
    private func file(for id: Int) async -> URL? {
        guard !isRemoved, let url = downloadURL?(id) else { return nil }

        let file = files[id] ?? startDownload(id: id, url: url)
        let value = await file.value

        // Let a later lookup retry a failed download.
        if value == nil, files[id] == file {
            files[id] = nil
        }

        return isRemoved ? nil : value
    }

    private func startDownload(id: Int, url: URL) -> Task<URL?, Never> {
        var request = URLRequest(url: url)

        if let accessToken {
            // X-Emby-Token is ignored when the server disables legacy authorization.
            request.setValue("MediaBrowser Token=\"\(accessToken)\"", forHTTPHeaderField: "Authorization")
        }

        let file = Task { @MainActor [session, directoryPath] () -> URL? in
            guard let (location, response) = try? await session.download(for: request),
                  let downloadedFile = try? File(path: location.path)
            else { return nil }

            // Clean up a download that wasn't moved into place.
            var isStored = false

            defer {
                if !isStored {
                    try? downloadedFile.delete()
                }
            }

            // A download finishing after `remove()` is cancelled and discarded here.
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode,
                  (200 ..< 300).contains(statusCode),
                  !Task.isCancelled
            else { return nil }

            do {
                let directory = try Folder.temporary.createSubfolderIfNeeded(at: directoryPath)
                try downloadedFile.move(to: directory)
                try downloadedFile.rename(to: "\(id)", keepExtension: false)

                isStored = true

                return downloadedFile.url
            } catch {
                return nil
            }
        }

        files[id] = file

        return file
    }

    /// Cancels downloads and deletes every file. Later lookups return `nil`.
    func remove() {
        guard !isRemoved else { return }

        isRemoved = true

        preloadTask?.cancel()
        files.values.forEach { $0.cancel() }
        files.removeAll()
        latestImage = nil

        session.invalidateAndCancel()
        try? Folder.temporary.subfolder(at: directoryPath).delete()
    }
}
