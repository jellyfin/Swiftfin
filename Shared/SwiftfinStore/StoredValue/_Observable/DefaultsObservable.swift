//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults

@MainActor
final class DefaultsObservable<Value: Storable>: ObservableObject, _StoredValueObservable {

    private var onObjectChanged: (() -> Void)?
    private var task: Task<Void, Never>?

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
        task?.cancel()

        task = .detached(priority: .userInitiated) { @MainActor [weak self, key] in
            for await _ in Defaults.updates(key._defaultKey) {
                guard let self else { return }

                self.onObjectChanged?()
            }
        }
    }
}
