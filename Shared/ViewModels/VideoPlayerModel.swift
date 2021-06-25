//
 /* 
  * SwiftFin is subject to the terms of the Mozilla Public
  * License, v2.0. If a copy of the MPL was not distributed with this
  * file, you can obtain one at https://mozilla.org/MPL/2.0/.
  *
  * Copyright 2021 Aiden Vigue & Jellyfin Contributors
  */

import SwiftUI
import JellyfinAPI

struct Subtitle {
    var name: String
    var id: Int32
    var url: URL?
    var delivery: SubtitleDeliveryMethod
    var codec: String
    var langCode: String
}

struct AudioTrack {
    var name: String
    var langCode: String
    var id: Int32
}

class PlaybackItem: ObservableObject {
    @Published var videoType: PlayMethod = .directPlay
    @Published var videoUrl: URL = URL(string: "https://example.com")!
}
