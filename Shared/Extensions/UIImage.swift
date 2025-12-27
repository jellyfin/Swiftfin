//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import UIKit

extension UIImage {

    func getTileImage(
        columns: Int,
        rows: Int,
        index: Int
    ) -> UIImage? {
        let x = index % columns
        let y = index / columns

        let imageWidth = Int(size.width)
        let imageHeight = Int(size.height)
        let tileWidth = imageWidth / columns
        let tileHeight = imageHeight / rows

        let rect = CGRect(
            x: x * tileWidth,
            y: y * tileHeight,
            width: tileWidth,
            height: tileHeight
        )

        if let cgImage = cgImage?.cropping(to: rect) {
            return UIImage(cgImage: cgImage)
        }

        return nil
    }
}
