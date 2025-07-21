//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Combine

class JumpProgressObserver: ObservableObject {

    private var timer: PokeIntervalTimer = .init(defaultInterval: 2)
    private var timerCancellable: AnyCancellable?

    private(set) var jumps: Int = 0
    private var isForward = true

    init() {
        timerCancellable = timer.hasFired
            .sink { _ in
                self.jumps = 0
            }
    }

    func jumpForward() {
        if isForward {
            jumps += 1
        } else {
            jumps = 1
            isForward = true
        }

        timer.poke()
    }

    func jumpBackward() {
        if !isForward {
            jumps += 1
        } else {
            jumps = 1
            isForward = false
        }

        timer.poke()
    }
}
