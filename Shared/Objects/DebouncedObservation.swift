//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import AsyncAlgorithms

@MainActor
enum DebouncedObservation {

    /// Starts an observation whose lifetime is controlled by the returned task.
    static func observe<Input: Equatable & Sendable>(
        _ input: @escaping @MainActor @Sendable () -> Input,
        for interval: Duration,
        onChange: @escaping @MainActor @Sendable (Input) -> Void = { _ in },
        onDebounce: @escaping @MainActor @Sendable (Input) -> Void
    ) -> Task<Void, Never> {
        Task {
            await run(input, for: interval, onChange: onChange, onDebounce: onDebounce)
        }
    }

    /// Delivers distinct current inputs to `onChange` before debouncing further work.
    /// Runs until the calling task is cancelled, discarding pending or stale snapshots.
    static func run<Input: Equatable & Sendable>(
        _ input: @escaping @MainActor @Sendable () -> Input,
        for interval: Duration,
        onChange: @escaping @MainActor @Sendable (Input) -> Void = { _ in },
        onDebounce: @escaping @MainActor @Sendable (Input) -> Void
    ) async {
        let inputs = ObservableValues(input)
            .removeDuplicates()
            .map { @MainActor value async in
                guard !Task.isCancelled, value == input() else { return value }

                onChange(value)
                return value
            }

        for await value in inputs.debounce(for: interval) {
            guard !Task.isCancelled else { return }
            guard value == input() else { continue }

            onDebounce(value)
        }
    }
}
