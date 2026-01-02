//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine

// TODO: remove

struct LegacyEventPublisher<T>: Publisher {
    typealias Output = T
    typealias Failure = Never

    private let subject = PassthroughSubject<T, Never>()

    func receive<S>(subscriber: S) where S: Subscriber, Never == S.Failure, T == S.Input {
        subject.receive(subscriber: subscriber)
    }

    func send(_ value: T) {
        subject.send(value)
    }
}
