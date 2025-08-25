//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation

// TODO: aspect fill state

class VideoPlayerContainerState: ObservableObject {

    @Published
    var isPresentingOverlay: Bool = false {
        didSet {
            isPresentingPlaybackControls = isPresentingOverlay
        }
    }

    @Published
    var isPresentingPlaybackControls: Bool = false

    @Published
    private(set) var isPresentingSupplement: Bool = false

    @Published
    var isScrubbing: Bool = false

    @Published
    var selectedSupplement: AnyMediaPlayerSupplement? = nil {
        didSet {
            isPresentingSupplement = selectedSupplement != nil
        }
    }

    @Published
    var supplementOffset: CGFloat = 0.0

    let timer = PokeIntervalTimer()
}
