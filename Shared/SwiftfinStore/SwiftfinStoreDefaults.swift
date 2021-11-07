//
 /* 
  * SwiftFin is subject to the terms of the Mozilla Public
  * License, v2.0. If a copy of the MPL was not distributed with this
  * file, you can obtain one at https://mozilla.org/MPL/2.0/.
  *
  * Copyright 2021 Aiden Vigue & Jellyfin Contributors
  */

import Defaults
import Foundation

extension SwiftfinStore {
    
    enum Defaults {
        
        static let suite: UserDefaults = {
            return UserDefaults(suiteName: "swiftfinstore-defaults")!
        }()
    }
}

extension Defaults.Keys {
    static let lastServerUserID = Defaults.Key<String?>("lastServerUserID", suite: SwiftfinStore.Defaults.suite)
    
    static let defaultHTTPScheme = Key<HTTPScheme>("defaultHTTPScheme", default: .http, suite: SwiftfinStore.Defaults.suite)
    static let inNetworkBandwidth = Key<Int>("InNetworkBandwidth", default: 40_000_000, suite: SwiftfinStore.Defaults.suite)
    static let outOfNetworkBandwidth = Key<Int>("OutOfNetworkBandwidth", default: 40_000_000, suite: SwiftfinStore.Defaults.suite)
    static let isAutoSelectSubtitles = Key<Bool>("isAutoSelectSubtitles", default: false, suite: SwiftfinStore.Defaults.suite)
    static let autoSelectSubtitlesLangCode = Key<String>("AutoSelectSubtitlesLangCode", default: "Auto", suite: SwiftfinStore.Defaults.suite)
    static let autoSelectAudioLangCode = Key<String>("AutoSelectAudioLangCode", default: "Auto", suite: SwiftfinStore.Defaults.suite)
    static let appAppearance = Key<AppAppearance>("appAppearance", default: .system, suite: SwiftfinStore.Defaults.suite)
    static let videoPlayerJumpForward = Key<VideoPlayerJumpLength>("videoPlayerJumpForward", default: .thirty, suite: SwiftfinStore.Defaults.suite)
    static let videoPlayerJumpBackward = Key<VideoPlayerJumpLength>("videoPlayerJumpBackward", default: .thirty, suite: SwiftfinStore.Defaults.suite)
}
