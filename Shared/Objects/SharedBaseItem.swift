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

/// Wraps a DTO in a shared item record without merging stale snapshots on assignment.
@MainActor
@propertyWrapper
struct SharedBaseItem: Hashable {

    private(set) var entry: ItemEntry

    init(wrappedValue: BaseItemDto) {
        let store = Container.shared.currentUserSession()?.items

        let record: ItemRecord = if let store, let shared = try? store.reference(to: wrappedValue) {
            shared
        } else if let store, !store.isActive, let id = wrappedValue.id {
            // An identified item from an inactive session must stay unavailable.
            ItemRecord(id: ItemKey(itemID: id))
        } else {
            // Presentation-only records are not entered into the session store.
            ItemRecord(
                id: ItemKey(itemID: wrappedValue.id ?? UUID().uuidString),
                presentationValue: wrappedValue
            )
        }

        entry = ItemEntry(item: record, occurrence: wrappedValue.playlistItemID)
    }

    var wrappedValue: BaseItemDto {
        get { entry.snapshot }
        set { self = SharedBaseItem(wrappedValue: newValue) }
    }

    var projectedValue: ItemEntry {
        entry
    }

    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(entry)
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

/// Wraps an optional DTO in a shared item record.
@MainActor
@propertyWrapper
struct OptionalSharedBaseItem {

    private var item: SharedBaseItem?

    init(wrappedValue: BaseItemDto?) {
        item = wrappedValue.map { SharedBaseItem(wrappedValue: $0) }
    }

    var wrappedValue: BaseItemDto? {
        get { item?.entry.value }
        set { item = newValue.map { SharedBaseItem(wrappedValue: $0) } }
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

/// Wraps a DTO collection in shared item records.
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
