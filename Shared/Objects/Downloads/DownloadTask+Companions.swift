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
import UIKit

/// Companion-file downloads that run after the media transfer finishes.
/// Flavor-agnostic — both direct and transcoded downloads need posters
/// and subtitles alongside the media file.
extension DownloadTask {

    /// Downloads poster / backdrop / thumb / logo into `imagesFolder`.
    /// Returns the manifest used to populate the resulting `DownloadItem`.
    func downloadImages(item: BaseItemDto) async -> [DownloadImage] {
        let kinds: [ImageType] = [.primary, .backdrop, .thumb, .logo]
        var images: [DownloadImage] = []

        for kind in kinds {
            if let image = await downloadImage(kind: kind, for: item) {
                images.append(image)
            }
        }

        return images
    }

    private func downloadImage(kind: ImageType, for item: BaseItemDto) async -> DownloadImage? {
        let sourceURL: URL? = {
            switch kind {
            case .primary:
                item.imageSource(.primary, maxWidth: 600).url
            case .backdrop:
                item.imageSource(.backdrop, maxWidth: 800).url
            case .thumb:
                item.imageSource(.thumb, maxWidth: 800).url
            case .logo:
                item.imageSource(.logo, maxWidth: 400).url
            default:
                nil
            }
        }()

        guard let sourceURL else { return nil }

        do {
            try FileManager.default.createDirectory(at: imagesFolder, withIntermediateDirectories: true)
            let (data, response) = try await URLSession.shared.data(from: sourceURL)

            let ext: String = response.mimeSubtype ?? "jpg"
            let filename = "\(kind.rawValue.capitalized).\(ext)"
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
                kind: kind,
                relativePath: filename,
                aspectRatio: aspectRatio
            )
        } catch {
            Logger.swiftfin().warning("Failed to download \(kind.rawValue) image: \(error.localizedDescription)")
            return nil
        }
    }

    /// Downloads external subtitle streams into `downloadFolder/Subtitles/`.
    /// Filenames are namespaced by language + stream index to avoid collisions
    /// (e.g. `eng.0.srt`, `fra.1.ass`).
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
        let url = userSession.client.url(path: deliveryURL)

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
