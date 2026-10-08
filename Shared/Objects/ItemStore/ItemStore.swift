//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import JellyfinAPI

/// Keeps weak references to records owned by views and collections
@MainActor
final class ItemStore {

    /// Identifies when a request began within this store
    struct RequestToken {

        fileprivate let revision: UInt64
    }

    /// Describes an item or collection change for store observers
    enum Change {

        case updated(Update)
        case deleted(String)
        /// Signals that collection membership or ordering may have changed
        case libraryChanged
        case invalidated
    }

    /// Identifies which part of an item changed
    struct Update {

        let itemID: String
        var metadataChanged = false
        var userDataChanged = false

        var hasChanges: Bool {
            metadataChanged || userDataChanged
        }
    }

    enum StoreError: Error {

        case invalidItemID
        case invalidSession
        case itemUnavailable
    }

    private let changeSubject = PassthroughSubject<Change, Never>()

    var changes: AnyPublisher<Change, Never> {
        changeSubject.eraseToAnyPublisher()
    }

    private(set) var isActive = true
    private var revision: UInt64 = 0
    private var records: [String: WeakBox<ItemRecord>] = [:]
    // Deleted IDs stay blocked even after their weak records are released
    private var deletedIDs: Set<String> = []
    private var insertionsUntilPrune = 128
    private var mutations: [String: [(id: UUID, task: Task<Void, Error>)]] = [:]

    /// Looks up an available shared record without creating one
    subscript(id: String) -> ItemRecord? {
        guard isAvailable(id: id) else { return nil }

        return records[id]?.value
    }

    /// Assigns a revision before sending so late responses cannot restore older data
    func beginRequest() throws -> RequestToken {
        guard isActive else { throw StoreError.invalidSession }

        revision += 1
        return RequestToken(revision: revision)
    }

    func validate() throws {
        try Task.checkCancellation()
        guard isActive else { throw StoreError.invalidSession }
    }

    /// Seeds a snapshot only when its shared record is first created
    func record(for value: BaseItemDto) throws -> ItemRecord {
        let id = try itemID(value)
        let acquisition = acquireRecord(id: id)
        let record = acquisition.record

        guard case .created = acquisition else { return record }

        let patch = try ItemPatch.snapshot(value)
        let program = try value.currentProgram.flatMap { $0.id == id ? nil : try self.record(for: $0) }
        // Snapshot data starts below every request revision
        try record.merge(patch, revision: 0, program: program)

        return record
    }

    /// Returns nil when a response has no usable ID or the item was deleted
    @discardableResult
    func merge(_ patch: ItemPatch, token: RequestToken) throws -> ItemRecord? {
        try validate()

        guard let id = try? itemID(patch.value) else { return nil }

        let acquisition = acquireRecord(id: id)

        if case .unavailable = acquisition {
            return nil
        }

        let record = acquisition.record

        var program: ItemRecord?

        // Nested programs share the parent request revision and merge scope
        if patch.scope != .metadataSnapshot, let value = patch.value.currentProgram, let object = patch.program,
           value.id != id
        {
            program = try merge(ItemPatch.decoded(value, object: object, scope: patch.scope), token: token)
        }

        let update = try record.merge(patch, revision: token.revision, program: program)

        // Initial record loads avoid triggering another collection refresh
        if case .existing = acquisition, update.hasChanges {
            changeSubject.send(.updated(update))
        }

        return record
    }

    /// Uses raw field names when an HTTP response provides them
    func mergeUserData(
        _ data: UserItemDataDto,
        fields: Set<String>? = nil,
        token: RequestToken
    ) throws {
        try validate()

        guard let id = data.itemID else { return }
        guard id.nilIfBlank != nil else { throw StoreError.invalidItemID }
        guard isAvailable(id: id) else { return }

        // Unloaded items can affect a collection without needing a retained record
        guard let record = self[id] else {
            changeSubject.send(.updated(Update(itemID: id, userDataChanged: true)))
            return
        }

        let patch = try ItemPatch(
            value: BaseItemDto(id: id, userData: data),
            fields: ["UserData"],
            userDataFields: fields ?? Set(JSONSerialization.encode(data).keys)
        )
        let update = try record.merge(patch, revision: token.revision, program: nil)
        if update.hasChanges {
            changeSubject.send(.updated(update))
        }
    }

    /// Replaces draft metadata without changing session user data
    func acceptMetadataDraft(_ value: BaseItemDto) throws {
        try validate()

        _ = try itemID(value)
        _ = try merge(ItemPatch.snapshot(value, scope: .metadataSnapshot), token: beginRequest())

        libraryDidChange()
    }

    /// Queues writes for each item while showing optimistic values immediately
    func mutateUserData(
        _ item: ItemRecord,
        field: ItemUserDataField,
        to value: Bool,
        operation: @escaping @MainActor () async throws -> (value: UserItemDataDto, fields: Set<String>)
    ) async throws {
        guard self[item.id] === item, item.value != nil else {
            throw StoreError.itemUnavailable
        }

        let itemID = item.id
        let mutationID = UUID()
        let previous = mutations[itemID]?.last?.task
        item.beginChange(id: mutationID, field: field, value: value)

        let task = Task {
            defer {
                item.endChange(id: mutationID)
                mutations[itemID]?.removeAll { $0.id == mutationID }

                if mutations[itemID]?.isEmpty == true {
                    mutations.removeValue(forKey: itemID)
                }
            }

            if let previous {
                // Failed writes do not block later changes
                _ = await previous.result
            }

            try validate()
            guard item.value != nil else { throw StoreError.itemUnavailable }

            var data = try await operation()
            try validate()
            guard item.value != nil else { throw StoreError.itemUnavailable }

            data.value.itemID = itemID

            // Confirmation gets a new revision to protect it from reads started during the write
            try mergeUserData(
                data.value,
                fields: data.fields,
                token: beginRequest()
            )
        }

        mutations[itemID, default: []].append((mutationID, task))

        try await withTaskCancellationHandler {
            try await task.value
        } onCancel: {
            task.cancel()
        }
    }

    func libraryDidChange() {
        guard isActive else { return }

        changeSubject.send(.libraryChanged)
    }

    /// Invalidates loaded items and blocks later responses for the same ID
    func delete(id: String) {
        guard isActive, deletedIDs.insert(id).inserted else { return }

        for mutation in mutations.removeValue(forKey: id) ?? [] {
            mutation.task.cancel()
        }

        records[id]?.value?.invalidate()
        changeSubject.send(.deleted(id))
    }

    /// Makes records held by existing views unavailable when the session ends
    func invalidate() {
        guard isActive else { return }

        isActive = false

        for mutation in mutations.values.joined() {
            mutation.task.cancel()
        }

        mutations.removeAll()

        for record in records.values {
            record.value?.invalidate()
        }

        records.removeAll()
        deletedIDs.removeAll()
        changeSubject.send(.invalidated)
        changeSubject.send(completion: .finished)
    }

    /// Distinguishes records when seeding or merging data
    private enum Acquisition {

        case existing(ItemRecord)
        case created(ItemRecord)
        case unavailable(ItemRecord)

        var record: ItemRecord {
            switch self {
            case let .existing(record), let .created(record), let .unavailable(record):
                record
            }
        }
    }

    private func isAvailable(id: String) -> Bool {
        isActive && !deletedIDs.contains(id)
    }

    /// Resolves record identity before deciding whether it can be updated
    private func acquireRecord(id: String) -> Acquisition {
        guard isActive else { return .unavailable(ItemRecord(id: id)) }

        let isAvailable = isAvailable(id: id)

        if let record = records[id]?.value {
            return isAvailable ? .existing(record) : .unavailable(record)
        }

        // Prune less often as the number of retained records grows
        if insertionsUntilPrune == 0 {
            records = records.filter { $0.value.value != nil }
            insertionsUntilPrune = max(128, records.count)
        }

        let record = ItemRecord(id: id)
        records[id] = WeakBox(value: record)
        insertionsUntilPrune -= 1

        return isAvailable ? .created(record) : .unavailable(record)
    }

    private func itemID(_ value: BaseItemDto) throws -> String {
        guard let id = value.id, id.nilIfBlank != nil else {
            throw StoreError.invalidItemID
        }

        return id
    }
}
