//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import Observation

@MainActor
@Observable
final class DeadlineTimer {

    private(set) var deadline: Date?

    @ObservationIgnored
    private var timer: Timer?
    @ObservationIgnored
    private let action: @MainActor () -> Void

    init(_ action: @escaping @MainActor () -> Void) {
        self.action = action
    }

    func start(until date: Date) {
        timer?.invalidate()
        deadline = date

        let timer = Timer(fire: date, interval: 0, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }

                self.timer = nil
                self.deadline = nil
                self.action()
            }
        }

        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func invalidate() {
        timer?.invalidate()
        timer = nil
        deadline = nil
    }
}
