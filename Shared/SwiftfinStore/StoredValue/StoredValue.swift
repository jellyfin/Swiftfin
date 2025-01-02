//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Combine
import CoreStore
import Factory
import Foundation
import SwiftUI

/// A property wrapper for a stored `AnyData` object.
@propertyWrapper
struct StoredValue<Value: Codable>: DynamicProperty {

    @ObservedObject
    private var observable: Observable

    let key: StoredValues.Key<Value>

    var projectedValue: Binding<Value> {
        $observable.value
    }

    var wrappedValue: Value {
        get {
            observable.value
        }
        nonmutating set {
            observable.value = newValue
        }
    }

    init(_ key: StoredValues.Key<Value>) {
        self.key = key
        self.observable = .init(key: key)
    }

    mutating func update() {
        _observable.update()
    }
}

extension StoredValue {

    final class Observable: ObservableObject {

        let key: StoredValues.Key<Value>

        let objectWillChange = ObservableObjectPublisher()
        private var objectPublisher: ObjectPublisher<AnyStoredData>?
        private var shouldListenToPublish: Bool = true

        var value: Value {
            get {
                guard key.name.isNotEmpty, key.ownerID.isNotEmpty else { return key.defaultValue() }

                let fetchedValue: Value? = try? AnyStoredData.fetch(
                    key.name,
                    ownerID: key.ownerID,
                    domain: key.domain
                )

                return fetchedValue ?? key.defaultValue()
            }
            set {
                guard key.name.isNotEmpty, key.ownerID.isNotEmpty else { return }
                shouldListenToPublish = false

                objectWillChange.send()

                try? AnyStoredData.store(
                    value: newValue,
                    key: key.name,
                    ownerID: key.ownerID,
                    domain: key.domain ?? ""
                )

                shouldListenToPublish = true
            }
        }

        init(key: StoredValues.Key<Value>) {
            self.key = key
            self.objectPublisher = makeObjectPublisher()
        }

        private func makeObjectPublisher() -> ObjectPublisher<AnyStoredData>? {

            guard key.name.isNotEmpty, key.ownerID.isNotEmpty else { return nil }

            let domain = key.domain ?? "none"

            let ownerFilter: Where<AnyStoredData> = Where(\.$ownerID == key.ownerID)
            let keyFilter: Where<AnyStoredData> = Where(\.$key == key.name)
            let domainFilter: Where<AnyStoredData> = Where(\.$domain == domain)

            let clause = From<AnyStoredData>()
                .where(ownerFilter && keyFilter && domainFilter)

            if let values = try? SwiftfinStore.dataStack.fetchAll(clause), let first = values.first {
                let publisher = first.asPublisher(in: SwiftfinStore.dataStack)

                publisher.addObserver(self) { [weak self] objectPublisher in
                    guard self?.shouldListenToPublish ?? false else { return }
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
                        key: key.name,
                        ownerID: key.ownerID,
                        domain: key.domain
                    )
                } catch {
                    Container.shared.logService().error("Unable to store and create publisher for: \(key)")

                    return nil
                }

                return makeObjectPublisher()
            }
        }
    }
}

enum StoredValues {

    typealias Keys = _AnyKey

    // swiftformat:disable enumnamespaces
    class _AnyKey {
        typealias Key = StoredValues.Key
    }

    /// A key to an `AnyData` object.
    ///
    /// - Important: if `name` or `ownerID` are empty, the default value
    ///              will always be retrieved and nothing will be set.
    final class Key<Value: Codable>: _AnyKey {

        let defaultValue: () -> Value
        let domain: String?
        let name: String
        let ownerID: String

        init(
            _ name: String,
            ownerID: String,
            domain: String?,
            default defaultValue: @autoclosure @escaping () -> Value
        ) {
            self.defaultValue = defaultValue
            self.domain = domain
            self.ownerID = ownerID
            self.name = name
        }

        /// Always returns the given value and does not
        /// set anything to storage.
        init(always: @autoclosure @escaping () -> Value) {
            defaultValue = always
            domain = nil
            name = ""
            ownerID = ""
        }
    }

    // TODO: find way that code isn't just copied from `Observable` above
    static subscript<Value: Codable>(key: Key<Value>) -> Value {
        get {
            guard key.name.isNotEmpty, key.ownerID.isNotEmpty else { return key.defaultValue() }

            let fetchedValue: Value? = try? AnyStoredData.fetch(
                key.name,
                ownerID: key.ownerID,
                domain: key.domain
            )

            return fetchedValue ?? key.defaultValue()
        }
        set {
            guard key.name.isNotEmpty, key.ownerID.isNotEmpty else { return }

            try? AnyStoredData.store(
                value: newValue,
                key: key.name,
                ownerID: key.ownerID,
                domain: key.domain ?? ""
            )
        }
    }
}
