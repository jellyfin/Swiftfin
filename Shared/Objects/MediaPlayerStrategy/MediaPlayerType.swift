//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

protocol MediaPlayerType {
    var videoPlayerProxy: (any MediaPlayerProxy)? { get set }
    var audioPlayerProxy: (any MediaPlayerProxy)? { get set }
    var pipPlayerProxy: (any MediaPlayerProxy)? { get set }
    var airPlayPlayerProxy: (any MediaPlayerProxy)? { get set }
}
