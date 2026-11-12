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
final class SleepTimer {

    private(set) var deadline: Date?

    @ObservationIgnored
    private var task: Task<Void, Never>?
    @ObservationIgnored
    private let onExpire: @MainActor () -> Void

    init(onExpire: @escaping @MainActor () -> Void) {
        self.onExpire = onExpire
    }

    func start(until date: Date) {
        task?.cancel()
        deadline = date

        task = Task { [weak self] in
            try? await Task.sleep(
                until: ContinuousClock.now + .seconds(date.timeIntervalSinceNow),
                clock: .continuous
            )
            guard !Task.isCancelled, let self else { return }

            task = nil
            deadline = nil
            onExpire()
        }
    }

    func cancel() {
        task?.cancel()
        task = nil
        deadline = nil
    }
}
