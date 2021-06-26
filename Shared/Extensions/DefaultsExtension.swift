//
 /* 
  * SwiftFin is subject to the terms of the Mozilla Public
  * License, v2.0. If a copy of the MPL was not distributed with this
  * file, you can obtain one at https://mozilla.org/MPL/2.0/.
  *
  * Copyright 2021 Aiden Vigue & Jellyfin Contributors
  */

import Foundation
import Defaults

extension Defaults.Keys {
    static let inNetworkBandwidth = Key<Int>("InNetworkBandwidth", default: 40_000_000)
    static let outOfNetworkBandwidth = Key<Int>("OutOfNetworkBandwidth", default: 40_000_000)
    static let isAutoSelectSubtitles = Key<Bool>("isAutoSelectSubtitles", default: false)
    static let autoSelectSubtitlesLangCode = Key<String>("AutoSelectSubtitlesLangCode", default: "Auto")
    static let autoSelectAudioLangCode = Key<String>("AutoSelectAudioLangCode", default: "Auto")
}
