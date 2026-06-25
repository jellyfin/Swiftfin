//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import CryptoKit
import Foundation
import JellyfinAPI
import Logging
import UIKit

extension DownloadTask {

    func downloadImages(item: BaseItemDto) async -> [DownloadImage] {
        var sourceLists: [[ImageSource]] = [
            item.portraitImageSources(maxWidth: 600),
            item.landscapeImageSources(maxWidth: 800),
            item.cinematicImageSources(maxWidth: 800),
            item.squareImageSources(maxWidth: 600),
            item.thumbImageSources(),
        ]

        if item.imageTags?[ImageType.logo.rawValue] != nil {
            sourceLists.append([item.imageSource(.logo, maxWidth: 400)])
        }

        var seen: Set<String> = []
        var images: [DownloadImage] = []

        for sources in sourceLists {
            for source in sources {
                guard let url = source.url else { continue }
                let pathKey = url.path
                guard seen.insert(pathKey).inserted else { continue }

                if let image = await downloadImage(from: url, pathKey: pathKey) {
                    images.append(image)
                }
            }
        }

        return images
    }

    private func downloadImage(from sourceURL: URL, pathKey: String) async -> DownloadImage? {
        do {
            try FileManager.default.createDirectory(at: imagesFolder, withIntermediateDirectories: true)
            let (data, response) = try await URLSession.shared.data(from: sourceURL)

            let ext: String = response.mimeSubtype ?? "jpg"
            let filename = "\(Self.filenameHash(pathKey)).\(ext)"
            let destination = imagesFolder.appendingPathComponent(filename)
            try? FileManager.default.removeItem(at: destination)
            try data.write(to: destination)

            let aspectRatio: CGFloat? = {
                guard let image = UIImage(data: data) else { return nil }
                let pixelHeight = image.size.height * image.scale
                guard pixelHeight > 0 else { return nil }
                return (image.size.width * image.scale) / pixelHeight
            }()

            return DownloadImage(
                pathKey: pathKey,
                relativePath: filename,
                aspectRatio: aspectRatio
            )
        } catch {
            Logger.swiftfin().warning("Failed to download image \(pathKey): \(error.localizedDescription)")
            return nil
        }
    }

    private static func filenameHash(_ pathKey: String) -> String {
        let digest = SHA256.hash(data: Data(pathKey.utf8))
        return digest.prefix(8).map { String(format: "%02x", $0) }.joined()
    }

    func downloadSubtitles(item: BaseItemDto, userSession: UserSession) async {
        let externalSubtitles = (item.mediaSources?.first?.mediaStreams ?? []).filter {
            $0.type == .subtitle && ($0.isExternal ?? false) && $0.deliveryURL != nil
        }

        guard !externalSubtitles.isEmpty else { return }

        let folder = downloadFolder.appendingPathComponent("Subtitles", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        for stream in externalSubtitles {
            await downloadSubtitle(stream: stream, into: folder, userSession: userSession)
        }
    }

    private func downloadSubtitle(stream: MediaStream, into folder: URL, userSession: UserSession) async {
        guard let deliveryURL = stream.deliveryURL else { return }
        guard let url = userSession.client.url(path: deliveryURL) else { return }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            let ext = stream.codec?.lowercased()
                ?? response.mimeSubtype
                ?? (url.pathExtension.isEmpty ? "srt" : url.pathExtension)
            let language = stream.language ?? "und"
            let index = stream.index ?? 0
            let filename = "\(language).\(index).\(ext)"
            let destination = folder.appendingPathComponent(filename)
            try? FileManager.default.removeItem(at: destination)
            try data.write(to: destination)
        } catch {
            Logger.swiftfin().warning("Failed to download subtitle stream \(stream.index ?? -1): \(error.localizedDescription)")
        }
    }
}
