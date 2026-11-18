//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import PerceptionCore

struct ObservableValues<Element: Sendable>: AsyncSequence, Sendable {

    typealias AsyncIterator = AsyncStream<Element>.Iterator

    private let read: @MainActor @Sendable () -> Element

    init(_ read: @escaping @MainActor @Sendable () -> Element) {
        self.read = read
    }

    func makeAsyncIterator() -> AsyncIterator {
        AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
            let task = Task { @MainActor [read] in
                if #available(iOS 26, tvOS 26, *) {
                    await Self.forward(Observations(read), to: continuation)
                } else {
                    await Self.forward(Perceptions(read), to: continuation)
                }

                continuation.finish()
            }

            continuation.onTermination = { _ in task.cancel() }
        }
        .makeAsyncIterator()
    }

    @MainActor
    private static func forward(
        _ values: some AsyncSequence<Element, Never>,
        to continuation: AsyncStream<Element>.Continuation
    ) async {
        for await value in values {
            guard !Task.isCancelled else { return }

            if case .terminated = continuation.yield(value) {
                return
            }
        }
    }
}
