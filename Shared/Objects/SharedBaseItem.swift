//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import FactoryKit
import Foundation
import JellyfinAPI

@MainActor
@propertyWrapper
struct SharedBaseItem: Hashable {

    private(set) var entry: ItemEntry

    init(wrappedValue: BaseItemDto) {
        let store = Container.shared.currentUserSession()?.items

        // Values without a session or usable ID are only for presentation
        let record = (try? store?.record(for: wrappedValue)) ?? ItemRecord(
            id: wrappedValue.id ?? UUID().uuidString,
            presentationValue: wrappedValue
        )

        entry = ItemEntry(item: record, occurrence: wrappedValue.playlistItemID)
    }

    var wrappedValue: BaseItemDto {
        get { entry.snapshot }
        set { self = SharedBaseItem(wrappedValue: newValue) }
    }

    var projectedValue: ItemEntry {
        get { entry }
        set { entry = newValue }
    }

    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(entry)
    }

    // Entry replacement must notify owners using Combine observation
    static subscript<Owner: ObservableObject>(
        _enclosingInstance owner: Owner,
        projected projectedKeyPath: ReferenceWritableKeyPath<Owner, ItemEntry>,
        storage storageKeyPath: ReferenceWritableKeyPath<Owner, Self>
    ) -> ItemEntry {
        get { owner[keyPath: storageKeyPath].projectedValue }
        set {
            (owner.objectWillChange as? ObservableObjectPublisher)?.send()
            owner[keyPath: storageKeyPath].projectedValue = newValue
        }
    }

    static subscript<Owner: ObservableObject>(
        _enclosingInstance owner: Owner,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<Owner, BaseItemDto>,
        storage storageKeyPath: ReferenceWritableKeyPath<Owner, Self>
    ) -> BaseItemDto {
        get { owner[keyPath: storageKeyPath].wrappedValue }
        set {
            (owner.objectWillChange as? ObservableObjectPublisher)?.send()
            owner[keyPath: storageKeyPath].wrappedValue = newValue
        }
    }
}

@MainActor
@propertyWrapper
struct OptionalSharedBaseItem {

    private var entry: ItemEntry?

    init(wrappedValue: BaseItemDto?) {
        entry = wrappedValue.map { SharedBaseItem(wrappedValue: $0).entry }
    }

    var wrappedValue: BaseItemDto? {
        get { entry?.value }
        set { entry = newValue.map { SharedBaseItem(wrappedValue: $0).entry } }
    }

    var projectedValue: ItemEntry? {
        get { entry }
        set { entry = newValue }
    }

    static subscript<Owner: ObservableObject>(
        _enclosingInstance owner: Owner,
        projected projectedKeyPath: ReferenceWritableKeyPath<Owner, ItemEntry?>,
        storage storageKeyPath: ReferenceWritableKeyPath<Owner, Self>
    ) -> ItemEntry? {
        get { owner[keyPath: storageKeyPath].projectedValue }
        set {
            (owner.objectWillChange as? ObservableObjectPublisher)?.send()
            owner[keyPath: storageKeyPath].projectedValue = newValue
        }
    }

    static subscript<Owner: ObservableObject>(
        _enclosingInstance owner: Owner,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<Owner, BaseItemDto?>,
        storage storageKeyPath: ReferenceWritableKeyPath<Owner, Self>
    ) -> BaseItemDto? {
        get { owner[keyPath: storageKeyPath].wrappedValue }
        set {
            (owner.objectWillChange as? ObservableObjectPublisher)?.send()
            owner[keyPath: storageKeyPath].wrappedValue = newValue
        }
    }
}

@MainActor
@propertyWrapper
struct SharedBaseItems: Hashable {

    private var items: [SharedBaseItem]

    init(wrappedValue: [BaseItemDto]) {
        items = wrappedValue.map { SharedBaseItem(wrappedValue: $0) }
    }

    var wrappedValue: [BaseItemDto] {
        get { items.compactMap(\.entry.value) }
        set { items = newValue.map { SharedBaseItem(wrappedValue: $0) } }
    }

    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(items)
    }

    static subscript<Owner: ObservableObject>(
        _enclosingInstance owner: Owner,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<Owner, [BaseItemDto]>,
        storage storageKeyPath: ReferenceWritableKeyPath<Owner, Self>
    ) -> [BaseItemDto] {
        get { owner[keyPath: storageKeyPath].wrappedValue }
        set {
            (owner.objectWillChange as? ObservableObjectPublisher)?.send()
            owner[keyPath: storageKeyPath].wrappedValue = newValue
        }
    }
}
