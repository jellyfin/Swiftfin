//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import CoreStore
import Logging

@MainActor
final class SQLObservable<Value: Storable>: ObservableObject, _StoredValueObservable {

    let key: StoredValues.Key<Value>

    private var objectPublisher: ObjectPublisher<AnyStoredData>?
    private var shouldListenToPublish: Bool = true
    private var onObjectChanged: (() -> Void)?

    var value: Value {
        get {
            guard key.name.isNotEmpty, key.ownerID.isNotEmpty else { return key.defaultValue() }

            let fetchedValue: Value? = try? AnyStoredData.fetch(
                ownerID: key.ownerID,
                field: key.field ?? key.name,
                key: key.name
            )

            return fetchedValue ?? key.defaultValue()
        }
        set {
            guard key.name.isNotEmpty, key.ownerID.isNotEmpty else { return }
            shouldListenToPublish = false

            onObjectChanged?()

            try? AnyStoredData.store(
                value: newValue,
                ownerID: key.ownerID,
                field: key.field ?? key.name,
                key: key.name
            )

            shouldListenToPublish = true
        }
    }

    init(_ key: StoredValues.Key<Value>, onObjectChanged: (() -> Void)? = nil) {
        self.key = key
        self.onObjectChanged = onObjectChanged
    }

    func observe() {
        self.objectPublisher = makeObjectPublisher()
    }

    private func makeObjectPublisher() -> ObjectPublisher<AnyStoredData>? {

        guard key.name.isNotEmpty, key.ownerID.isNotEmpty else { return nil }

        let field = key.field ?? key.name

        let ownerFilter: Where<AnyStoredData> = Where(\.$ownerID == key.ownerID)
        let keyFilter: Where<AnyStoredData> = Where(\.$key == key.name)
        let fieldFilter: Where<AnyStoredData> = Where(\.$field == field)

        let clause = From<AnyStoredData>()
            .where(ownerFilter && keyFilter && fieldFilter)

        if let values = try? SwiftfinStore.dataStack.fetchAll(clause), let first = values.first {
            let publisher = first.asPublisher(in: SwiftfinStore.dataStack)

            publisher.addObserver(self) { [weak self] objectPublisher in
                guard self?.shouldListenToPublish == true else { return }
                guard let data = objectPublisher.object?.data else { return }
                guard let newValue = try? JSONDecoder().decode(Value.self, from: data) else { fatalError() }

                DispatchQueue.main.async {
                    self?.value = newValue
                }
            }

            return publisher
        } else {
            // Stored value doesn't exist but we want to observe it.
            // Create default and get new publisher

            // TODO: this still store unnecessary data if never changed,
            //       observe if changes were made and delete on deinit

            do {
                try AnyStoredData.store(
                    value: key.defaultValue(),
                    ownerID: key.ownerID,
                    field: key.field ?? key.name,
                    key: key.name
                )
            } catch {
                Logger.swiftfin().error("Unable to store and create publisher for: \(key)")

                return nil
            }

            return makeObjectPublisher()
        }
    }
}
