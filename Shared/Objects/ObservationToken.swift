//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Observation

/// Tracks observable values outside views.
/// Only reads establish dependencies. Changes are delivered after mutation.
@MainActor
final class ObservationToken: @preconcurrency Cancellable {

    private var update: (() -> Void)?

    init<Value>(
        _ read: @escaping () -> Value,
        onChange: @escaping (Value) -> Void
    ) {
        update = { [weak self] in
            let value = withObservationTracking(read) { [weak self] in
                Task { @MainActor [weak self] in
                    self?.update?()
                }
            }

            onChange(value)
        }

        update?()
    }

    func cancel() {
        update = nil
    }
}
