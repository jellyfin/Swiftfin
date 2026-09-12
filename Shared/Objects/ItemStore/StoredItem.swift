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

/// Adapts DTO-based view APIs to shared ownership. Reading creates a temporary snapshot;
/// assigning changes the reference, never patches an existing record with an old snapshot.
@MainActor
@propertyWrapper
struct StoredItem: Hashable {

    private(set) var entry: ItemEntry

    init(wrappedValue: BaseItemDto) {
        let store = Container.shared.currentUserSession()?.items
        let record: ItemRecord = if let store, let shared = try? store.reference(to: wrappedValue) {
            shared
        } else if let store, let id = wrappedValue.id, !store.isActive {
            ItemRecord(id: ItemKey(sessionID: store.sessionID, itemID: id))
        } else {
            // ID-less section headings and previews are local presentation data.
            ItemRecord(presentation: wrappedValue)
        }
        entry = ItemEntry(
            item: record,
            occurrence: wrappedValue.playlistItemID,
            presentationType: wrappedValue.type == .folder && record.value?.type != .folder ? .folder : nil
        )
    }

    var wrappedValue: BaseItemDto {
        get { entry.snapshot }
        set { self = StoredItem(wrappedValue: newValue) }
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

@MainActor
@propertyWrapper
struct StoredOptionalItem {
    private var item: StoredItem?

    init(wrappedValue: BaseItemDto?) {
        item = wrappedValue.map { StoredItem(wrappedValue: $0) }
    }

    var wrappedValue: BaseItemDto? {
        get { item?.entry.value }
        set { item = newValue.map { StoredItem(wrappedValue: $0) } }
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
struct StoredItems: Hashable {
    private var items: [StoredItem]

    init(wrappedValue: [BaseItemDto]) {
        items = wrappedValue.map { StoredItem(wrappedValue: $0) }
    }

    var wrappedValue: [BaseItemDto] {
        get { items.compactMap(\.entry.value) }
        set { items = newValue.map { StoredItem(wrappedValue: $0) } }
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
