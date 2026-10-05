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

/// Views and collections own records; each session's store keeps weak references.
///
/// Stored for shared media item values.
@MainActor
final class ItemStore {

    /// Ties a response to its session and request order.
    struct RequestToken {

        fileprivate let sessionID: UUID
        fileprivate let revision: UInt64
    }

    /// Describes an item or collection change for store observers.
    enum Change {

        case updated(Update)
        case deleted(String)
        /// Membership or ordering changed, including unloaded items.
        case libraryChanged
        case invalidated
    }

    /// Identifies which part of a retained item changed.
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

    let sessionID = UUID()
    private(set) var isActive = true
    private var revision: UInt64 = 0
    private var records: [String: WeakBox<ItemRecord>] = [:]
    private var deletedIDs: Set<String> = []
    private var insertionsUntilPrune = 128
    private var mutations: [String: [(id: UUID, task: Task<Void, Error>)]] = [:]

    func retainedRecord(id: String) -> ItemRecord? {
        records[id]?.value
    }

    /// Create before sending a request to order its updates against other responses.
    func beginRequest() throws -> RequestToken {
        guard isActive else { throw StoreError.invalidSession }

        revision += 1
        return RequestToken(sessionID: sessionID, revision: revision)
    }

    func validate(_ token: RequestToken) throws {
        try Task.checkCancellation()
        guard isActive, token.sessionID == sessionID else { throw StoreError.invalidSession }
    }

    /// Resolve a retained snapshot without letting a view constructor overwrite newer data.
    func reference(to value: BaseItemDto) throws -> ItemRecord {
        guard isActive else { throw StoreError.invalidSession }

        let id = try itemID(value)
        if let record = records[id]?.value {
            return record
        }
        let record = record(for: id)
        if !deletedIDs.contains(id) {
            let patch = try ItemPatch.snapshot(value)
            let program = try value.currentProgram.flatMap { $0.id == id ? nil : try reference(to: $0) }
            try record.merge(patch, revision: 0, program: program)
        }
        return record
    }

    @discardableResult
    func merge(_ patch: ItemPatch, token: RequestToken) throws -> ItemRecord? {
        try validate(token)
        let id = try itemID(patch.value)
        guard !deletedIDs.contains(id) else { return nil }

        let record = record(for: id)
        var program: ItemRecord?
        if !patch.replacesMetadata, let value = patch.value.currentProgram, let object = patch.program,
           value.id != id
        {
            program = try merge(ItemPatch.decoded(value, object: object), token: token)
        }
        let wasRetained = record.value != nil
        let update = try record.merge(patch, revision: token.revision, program: program)
        // Loading a new page establishes membership; it must not trigger another fetch.
        if wasRetained, update.hasChanges {
            changeSubject.send(.updated(update))
        }
        return record
    }

    /// HTTP replies supply raw field names; socket DTOs use their encoded fields.
    func mergeUserData(_ data: UserItemDataDto, fields: Set<String>? = nil, token: RequestToken) throws {
        try validate(token)
        guard let id = data.itemID, !deletedIDs.contains(id) else { return }
        guard id.nilIfBlank != nil else { throw StoreError.invalidItemID }

        let patch = try ItemPatch(
            value: BaseItemDto(id: id, userData: data),
            fields: ["UserData"],
            userDataFields: fields ?? Set(CodableFields.encode(data).keys)
        )
        let record = record(for: id)
        let update = try record.merge(patch, revision: token.revision, program: nil)
        // Actions and socket updates can affect collections even when the item isn't loaded.
        if update.hasChanges {
            changeSubject.send(.updated(update))
        }
    }

    /// Nil draft fields clear metadata; session user data is preserved.
    func acceptMetadataDraft(_ value: BaseItemDto, token: RequestToken) throws {
        try validate(token)
        _ = try merge(ItemPatch.snapshot(value, replacesMetadata: true), token: beginRequest())
        libraryDidChange()
    }

    /// Serialize writes while preserving later optimistic changes if an earlier write fails.
    func mutateUserData(
        _ item: ItemRecord,
        field: ItemUserDataField,
        to value: Bool,
        operation: @escaping @MainActor () async throws -> (value: UserItemDataDto, fields: Set<String>)
    ) async throws {
        guard item.id.sessionID == sessionID, item.value != nil else { throw StoreError.itemUnavailable }

        let itemID = item.id.itemID
        let token = try beginRequest()
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
                _ = await previous.result
            }
            try validate(token)
            guard item.value != nil else { throw StoreError.itemUnavailable }

            var data = try await operation()
            try validate(token)
            guard item.value != nil else { throw StoreError.itemUnavailable }

            data.value.itemID = itemID
            // A new revision prevents reads started during the write from restoring stale data.
            try mergeUserData(data.value, fields: data.fields, token: beginRequest())
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

    func delete(id: String) {
        guard isActive, deletedIDs.insert(id).inserted else { return }

        for mutation in mutations.removeValue(forKey: id) ?? [] {
            mutation.task.cancel()
        }
        records[id]?.value?.invalidate()
        changeSubject.send(.deleted(id))
    }

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

    private func prune() {
        records = records.filter { $0.value.value != nil }
        insertionsUntilPrune = max(128, records.count)
    }

    private func record(for id: String) -> ItemRecord {
        if let record = records[id]?.value {
            return record
        }
        // Only discard dead weak references. Space scans with the registry size so
        // loading a large, still-owned library does not repeatedly scan every item.
        if insertionsUntilPrune == 0 {
            prune()
        }
        let record = ItemRecord(id: ItemKey(sessionID: sessionID, itemID: id))
        records[id] = WeakBox(value: record)
        insertionsUntilPrune -= 1
        return record
    }

    private func itemID(_ value: BaseItemDto) throws -> String {
        guard let id = value.id, id.nilIfBlank != nil else {
            throw StoreError.invalidItemID
        }

        return id
    }
}
