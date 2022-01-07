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

extension MediaStream {
    
    func externalURL(base: String) -> URL? {
        guard let deliveryURL = deliveryUrl else { return nil }
        var baseComponents = URLComponents(string: base)
        baseComponents?.path += deliveryURL
        
        return baseComponents?.url
    }
}
