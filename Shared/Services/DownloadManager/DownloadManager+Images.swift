//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import UIKit

extension DownloadManager {

    func downloadItemImages(taskID: String, item: BaseItemDto) async -> [DownloadImage] {
        guard let task = task(id: taskID) else { return [] }
        let kinds: [ImageType] = [.primary, .backdrop, .thumb, .logo]
        var images: [DownloadImage] = []

        for kind in kinds {
            if let image = await downloadImage(kind: kind, for: item, into: task.imagesFolder) {
                images.append(image)
            }
        }

        return images
    }

    private func downloadImage(kind: ImageType, for item: BaseItemDto, into folder: URL) async -> DownloadImage? {
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
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            let (data, response) = try await URLSession.shared.data(from: sourceURL)

            let ext: String = response.mimeSubtype ?? "jpg"
            let filename = "\(kind.rawValue.capitalized).\(ext)"
            let destination = folder.appendingPathComponent(filename)
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
            logger.warning("Failed to download \(kind.rawValue) image: \(error.localizedDescription)")
            return nil
        }
    }
}
