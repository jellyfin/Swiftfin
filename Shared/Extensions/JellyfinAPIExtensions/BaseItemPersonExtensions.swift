/* SwiftFin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import Foundation
import JellyfinAPI
import UIKit

extension BaseItemPerson {
    func getImage(baseURL: String, maxWidth: Int) -> URL {
        let imageType = "Primary"
        let imageTag = primaryImageTag ?? ""

        let x = UIScreen.main.nativeScale * CGFloat(maxWidth)

        let urlString = "\(baseURL)/Items/\(id ?? "")/Images/\(imageType)?maxWidth=\(String(Int(x)))&quality=85&tag=\(imageTag)"
        return URL(string: urlString)!
    }

    func getBlurHash() -> String {
        let rawImgURL = getImage(baseURL: "", maxWidth: 1).absoluteString
        let imgTag = rawImgURL.components(separatedBy: "&tag=")[1]

        return imageBlurHashes?.primary?[imgTag] ?? "001fC^"
    }
}

extension BaseItemPerson: PortraitImageStackable {
    public func imageURLContsructor(maxWidth: Int) -> URL {
        return self.getImage(baseURL: ServerEnvironment.current.server.baseURI!, maxWidth: maxWidth)
    }
    
    public var title: String {
        return self.name ?? ""
    }
    
    public var description: String? {
        return self.role
    }
    
    public var blurHash: String {
        return self.getBlurHash()
    }
}
