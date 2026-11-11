//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import Observation

@MainActor
@Observable
class JumpProgressObserver {

    private let interval: TimeInterval
    private var isForward = true
    private(set) var jumps: Int = 0
    let timer: PokeIntervalTimer

    @ObservationIgnored
    private var timerCancellable: AnyCancellable?

    init(interval: TimeInterval = 2) {
        self.interval = interval

        timer = .init(
            defaultInterval: interval
        )

        timerCancellable = timer
            .sink { [weak self] _ in
                guard let self else { return }

                self.jumps = 0
            }
    }

    func reset() {
        jumps = 0
    }

    func jumpForward(interval: TimeInterval? = nil) {
        if isForward {
            jumps += 1
        } else {
            jumps = 1
            isForward = true
        }

        timer.poke(interval: interval ?? self.interval)
    }

    func jumpBackward(interval: TimeInterval? = nil) {
        if !isForward {
            jumps += 1
        } else {
            jumps = 1
            isForward = false
        }

        timer.poke(interval: interval ?? self.interval)
    }
}
