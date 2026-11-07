//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation

@MainActor
protocol SharedHandle {

    associatedtype Value

    static func resolve(_ value: Value) -> Self

    var value: Value? { get }

    var snapshot: Value { get }
}

@MainActor
@propertyWrapper
struct SharedElement<Handle: SharedHandle> {

    private nonisolated(unsafe) var handle: Handle

    init(wrappedValue: Handle.Value) {
        handle = Handle.resolve(wrappedValue)
    }

    var wrappedValue: Handle.Value {
        get { handle.snapshot }
        set { handle = Handle.resolve(newValue) }
    }

    var projectedValue: Handle {
        get { handle }
        set { handle = newValue }
    }

    static subscript<Owner: ObservableObject>(
        _enclosingInstance owner: Owner,
        projected projectedKeyPath: ReferenceWritableKeyPath<Owner, Handle>,
        storage storageKeyPath: ReferenceWritableKeyPath<Owner, Self>
    ) -> Handle {
        get { owner[keyPath: storageKeyPath].projectedValue }
        set {
            (owner.objectWillChange as? ObservableObjectPublisher)?.send()
            owner[keyPath: storageKeyPath].projectedValue = newValue
        }
    }

    static subscript<Owner: ObservableObject>(
        _enclosingInstance owner: Owner,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<Owner, Handle.Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<Owner, Self>
    ) -> Handle.Value {
        get { owner[keyPath: storageKeyPath].wrappedValue }
        set {
            (owner.objectWillChange as? ObservableObjectPublisher)?.send()
            owner[keyPath: storageKeyPath].wrappedValue = newValue
        }
    }
}

extension SharedElement: Equatable where Handle: Equatable {}

extension SharedElement: Hashable where Handle: Hashable {

    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(handle)
    }
}

@MainActor
@propertyWrapper
struct OptionalSharedElement<Handle: SharedHandle> {

    private var handle: Handle?

    init(wrappedValue: Handle.Value?) {
        handle = wrappedValue.map { Handle.resolve($0) }
    }

    var wrappedValue: Handle.Value? {
        get { handle?.value }
        set { handle = newValue.map { Handle.resolve($0) } }
    }

    var projectedValue: Handle? {
        get { handle }
        set { handle = newValue }
    }

    static subscript<Owner: ObservableObject>(
        _enclosingInstance owner: Owner,
        projected projectedKeyPath: ReferenceWritableKeyPath<Owner, Handle?>,
        storage storageKeyPath: ReferenceWritableKeyPath<Owner, Self>
    ) -> Handle? {
        get { owner[keyPath: storageKeyPath].projectedValue }
        set {
            (owner.objectWillChange as? ObservableObjectPublisher)?.send()
            owner[keyPath: storageKeyPath].projectedValue = newValue
        }
    }

    static subscript<Owner: ObservableObject>(
        _enclosingInstance owner: Owner,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<Owner, Handle.Value?>,
        storage storageKeyPath: ReferenceWritableKeyPath<Owner, Self>
    ) -> Handle.Value? {
        get { owner[keyPath: storageKeyPath].wrappedValue }
        set {
            (owner.objectWillChange as? ObservableObjectPublisher)?.send()
            owner[keyPath: storageKeyPath].wrappedValue = newValue
        }
    }
}

@MainActor
@propertyWrapper
struct SharedCollection<Handle: SharedHandle> {

    private nonisolated(unsafe) var handles: [Handle]

    init(wrappedValue: [Handle.Value]) {
        handles = wrappedValue.map { Handle.resolve($0) }
    }

    var wrappedValue: [Handle.Value] {
        get { handles.compactMap(\.value) }
        set { handles = newValue.map { Handle.resolve($0) } }
    }

    static subscript<Owner: ObservableObject>(
        _enclosingInstance owner: Owner,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<Owner, [Handle.Value]>,
        storage storageKeyPath: ReferenceWritableKeyPath<Owner, Self>
    ) -> [Handle.Value] {
        get { owner[keyPath: storageKeyPath].wrappedValue }
        set {
            (owner.objectWillChange as? ObservableObjectPublisher)?.send()
            owner[keyPath: storageKeyPath].wrappedValue = newValue
        }
    }
}

extension SharedCollection: Equatable where Handle: Equatable {}

extension SharedCollection: Hashable where Handle: Hashable {

    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(handles)
    }
}
