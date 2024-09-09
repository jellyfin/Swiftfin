//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Combine
import SwiftUI

class PollingTimer: ObservableObject {

    private let defaultInterval: TimeInterval
    private var pollSubject: PassthroughSubject<Void, Never> = .init()
    private var pollingWorkItem: DispatchWorkItem?

    init(defaultInterval: TimeInterval = -1) {
        self.defaultInterval = defaultInterval
    }

    var polls: AnyPublisher<Void, Never> {
        pollSubject
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }

    func poll(interval: TimeInterval = -1) {
        var interval = interval

        if interval < 0 {
            if defaultInterval < 0 {
                return
            } else {
                interval = defaultInterval
            }
        }

        pollingWorkItem?.cancel()

        let newPollItem = DispatchWorkItem {
            self.pollSubject.send(())
        }

        pollingWorkItem = newPollItem

        DispatchQueue.main.asyncAfter(deadline: .now() + interval, execute: newPollItem)
    }

    func stop() {
        pollingWorkItem?.cancel()
    }
}
