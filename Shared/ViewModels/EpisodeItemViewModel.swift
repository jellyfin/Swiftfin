//
/*
 * SwiftFin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import Combine
import Foundation
import JellyfinAPI

final class EpisodeItemViewModel: ItemViewModel {
    
    override func getItemDisplayName() -> String {
        guard let episodeLocator = item.getEpisodeLocator() else { return item.name ?? "" }
        return "\(episodeLocator)\n\(item.name ?? "")"
    }
    
    override func shouldDisplayRuntime() -> Bool {
        return false
    }
}
