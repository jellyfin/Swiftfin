//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults

@MainActor
final class DefaultsObservable<Value: Storable>: ObservableObject, _StoredValueObservable {
    private var cancellable: AnyCancellable?
    private var task: Task<Void, Never>?
    private var onObjectChanged: (() -> Void)?

    let key: StoredValues.Key<Value>

    init(_ key: StoredValues.Key<Value>, onObjectChanged: (() -> Void)? = nil) {
        self.key = key
        self.onObjectChanged = onObjectChanged
    }

    var value: Value {
        get {
            Defaults[key._defaultKey]
        }
        set {
            Defaults[key._defaultKey] = newValue
        }
    }

    deinit {
        task?.cancel()
    }

    func observe() {
        // We only use this on the latest OSes (as of adding this) since the backdeploy library has a lot of bugs.
        task?.cancel()

        // The `@MainActor` is important as the `.send()` method doesn't inherit the `@MainActor` from the class.
        task = .detached(priority: .userInitiated) { @MainActor [weak self, key] in
            for await _ in Defaults.updates(key._defaultKey) {
                guard let self else {
                    return
                }

                self.onObjectChanged?()
            }
        }
    }
}
