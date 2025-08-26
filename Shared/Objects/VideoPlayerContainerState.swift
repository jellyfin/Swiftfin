//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import SwiftUI

// TODO: aspect fill state
// TODO: scrubbed seconds

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
    private(set) var isPresentingSupplement: Bool = false {
        didSet {
            if isPresentingSupplement {
                timer.poke()
            } else {
                timer.stop()
            }
        }
    }

    @Published
    var isScrubbing: Bool = false {
        didSet {
            if isScrubbing {
                timer.stop()
            } else {
                timer.poke()
            }
        }
    }

    @Published
    var selectedSupplement: AnyMediaPlayerSupplement? = nil {
        didSet {
            isPresentingSupplement = selectedSupplement != nil
        }
    }

    @Published
    var supplementOffset: CGFloat = 0.0

    var scrubbedSeconds: PublishedBox<Duration> = .init(initialValue: .zero)
    let timer = PokeIntervalTimer()

    private var timerCancellable: AnyCancellable?

    init() {
        timerCancellable = timer.hasFired.sink { [weak self] in
            guard self?.isScrubbing == false else { return }

            withAnimation(.linear(duration: 0.25)) {
                self?.isPresentingOverlay = false
            }
        }
    }
}
