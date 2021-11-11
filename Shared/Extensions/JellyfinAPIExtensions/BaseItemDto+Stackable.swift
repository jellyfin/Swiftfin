//
 /* 
  * SwiftFin is subject to the terms of the Mozilla Public
  * License, v2.0. If a copy of the MPL was not distributed with this
  * file, you can obtain one at https://mozilla.org/MPL/2.0/.
  *
  * Copyright 2021 Aiden Vigue & Jellyfin Contributors
  */

import Foundation
import JellyfinAPI

// MARK: PortraitImageStackable
extension BaseItemDto: PortraitImageStackable {
    public func imageURLContsructor(maxWidth: Int) -> URL {
        return self.getPrimaryImage(maxWidth: maxWidth)
    }

    public var title: String {
        return self.name ?? ""
    }

    public var description: String? {
        switch self.itemType {
        case .season:
            guard let productionYear = productionYear else { return nil }
            return "\(productionYear)"
        case .episode:
            return getEpisodeLocator()
        default:
            return nil
        }
    }

    public var blurHash: String {
        return self.getPrimaryImageBlurHash()
    }

    public var failureInitials: String {
        guard let name = self.name else { return "" }
        let initials = name.split(separator: " ").compactMap({ String($0).first })
        return String(initials)
    }
}
