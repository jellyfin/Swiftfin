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

@MainActor
final class ItemStore {

    struct RequestToken {
        fileprivate let sessionID: UUID
        fileprivate let revision: UInt64
    }

    enum Change {
        case updated(Update)
        case deleted(String)
        case invalidated
    }

    /// Describes a confirmed change, without copying item data out of the store.
    struct Update {
        let itemID: String
        var metadataChanged = false
        var userDataChanged = false

        var isEmpty: Bool {
            !metadataChanged && !userDataChanged
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

    let actionErrors = PassthroughSubject<Error, Never>()
    let sessionID = UUID()
    weak var session: AnyObject?
    private(set) var isActive = true
    private var revision: UInt64 = 0
    private var records: [String: WeakBox<ItemRecord>] = [:]
    private var deletedIDs: Set<String> = []
    private var insertionsSincePrune = 0
    private var mutations: [String: [(id: UUID, task: Task<Void, Error>)]] = [:]
    var subscriptions = Set<AnyCancellable>()

    func retainedRecord(id: String) -> ItemRecord? {
        records[id]?.value
    }

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
            let patch = try ItemPatch(value: value)
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
            program = try merge(ItemPatch(value: value, object: object), token: token)
        }
        let wasRetained = record.value != nil
        let update = try record.merge(patch, revision: token.revision, program: program)
        // Loading a new page establishes membership; it must not trigger another fetch.
        if wasRetained, !update.isEmpty {
            changeSubject.send(.updated(update))
        }
        return record
    }

    func mergeUserData(_ data: UserItemDataDto, token: RequestToken) throws {
        try mergeUserData(ItemUserDataPatch(value: data), token: token)
    }

    func mergeUserData(_ data: ItemUserDataPatch, token: RequestToken) throws {
        try validate(token)
        guard let id = data.value.itemID, !deletedIDs.contains(id) else { return }
        guard !id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw StoreError.invalidItemID }
        let fields = Dictionary(uniqueKeysWithValues: data.fields.map { ($0, NSNull() as Any) })
        let patch = ItemPatch(value: BaseItemDto(id: id, userData: data.value), object: ["UserData": fields])
        let record = record(for: id)
        let update = try record.merge(patch, revision: token.revision, program: nil)
        // Actions and socket updates can affect collections even when the item isn't loaded.
        if !update.isEmpty {
            changeSubject.send(.updated(update))
        }
    }

    /// Editors submit complete metadata drafts. Their nil fields are intentional clears;
    /// user data belongs to the current session and is never copied from an editing draft.
    func acceptMetadataDraft(_ value: BaseItemDto, token: RequestToken) throws {
        try validate(token)
        _ = try merge(ItemPatch(value: value, replacesMetadata: true), token: beginRequest())
    }

    /// Serialize writes for an item. Pending changes overlay confirmed data, so a failed
    /// earlier operation can never roll back a later choice or another field.
    func mutateUserData(
        _ entry: ItemEntry,
        field: ItemUserDataField,
        to value: Bool,
        operation: @escaping @MainActor () async throws -> ItemUserDataPatch
    ) async throws {
        guard entry.id.item.sessionID == sessionID, entry.value != nil else { throw StoreError.itemUnavailable }
        let token = try beginRequest()
        let mutationID = UUID()
        let previous = mutations[entry.itemID]?.last?.task
        entry.item.beginChange(id: mutationID, field: field, value: value)
        let task = Task {
            defer {
                entry.item.endChange(id: mutationID)
                mutations[entry.itemID]?.removeAll { $0.id == mutationID }
                if mutations[entry.itemID]?.isEmpty == true {
                    mutations.removeValue(forKey: entry.itemID)
                }
            }
            if let previous {
                _ = await previous.result
            }
            try validate(token)
            guard entry.value != nil else { throw StoreError.itemUnavailable }
            var data = try await operation()
            try validate(token)
            guard entry.value != nil else { throw StoreError.itemUnavailable }
            data.value.itemID = entry.itemID
            // Confirm and remove the overlay before the next queued write starts.
            // Reads started during the write must not restore its old state.
            try mergeUserData(data, token: beginRequest())
        }
        mutations[entry.itemID, default: []].append((mutationID, task))
        try await withTaskCancellationHandler {
            try await task.value
        } onCancel: {
            task.cancel()
        }
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
        subscriptions.removeAll()
        for record in records.values {
            record.value?.invalidate()
        }
        records.removeAll()
        deletedIDs.removeAll()
        changeSubject.send(.invalidated)
        changeSubject.send(completion: .finished)
        actionErrors.send(completion: .finished)
    }

    func prune() {
        records = records.filter { $0.value.value != nil }
        insertionsSincePrune = 0
    }

    private func record(for id: String) -> ItemRecord {
        if let record = records[id]?.value {
            return record
        }
        if insertionsSincePrune >= 128 {
            prune()
        }
        let record = ItemRecord(id: ItemKey(sessionID: sessionID, itemID: id))
        records[id] = WeakBox(value: record)
        insertionsSincePrune += 1
        return record
    }

    private func itemID(_ value: BaseItemDto) throws -> String {
        guard let id = value.id, !id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw StoreError.invalidItemID
        }
        return id
    }
}
