//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import UIKit

extension UIImage {

    func data(maxSize: Int? = 30_000_000) throws -> (data: Data, contentType: String) {
        let hasAlpha = cgImage.map {
            [.alphaOnly, .first, .last, .premultipliedFirst, .premultipliedLast].contains($0.alphaInfo)
        } == true

        func validate(_ data: Data) throws {
            guard let maxSize else { return }

            if data.count > maxSize {
                throw ErrorMessage(
                    "Image is too large (\(data.count.formatted(.byteCount(style: .file))) / \(maxSize.formatted(.byteCount(style: .file)))"
                )
            }
        }

        if hasAlpha, let pngData = pngData() {
            try validate(pngData)
            return (pngData, "image/png")
        } else if let jpgData = jpegData(compressionQuality: 1) {
            try validate(jpgData)
            return (jpgData, "image/jpeg")
        } else {
            throw ErrorMessage(L10n.unknownError)
        }
    }

    /// Crops tile `index` from a sheet of `tileSize`-pixel tiles laid out `columns` per row.
    ///
    /// Tiles are measured from the thumbnail size, not the sheet, since a partial sheet may be trimmed to the tiles it holds.
    func getTileImage(index: Int, columns: Int, tileSize: CGSize) -> UIImage? {
        guard index >= 0, columns > 0, let cgImage else { return nil }

        // CGImage crops in pixels, while UIImage.size is measured in points.
        let rect = CGRect(
            x: CGFloat(index % columns) * tileSize.width,
            y: CGFloat(index / columns) * tileSize.height,
            width: tileSize.width,
            height: tileSize.height
        )

        guard !rect.isEmpty,
              CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height).contains(rect),
              let tile = cgImage.cropping(to: rect)
        else { return nil }

        return UIImage(cgImage: tile, scale: scale, orientation: imageOrientation)
    }
}
