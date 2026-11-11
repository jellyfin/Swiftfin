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
final class UserStore {

    struct RequestToken {

        fileprivate let storeID: UUID
        fileprivate let revision: UInt64
    }

    enum Change {

        case updated(UserDto)
        case deleted(String)
    }

    enum StoreError: Error {

        case invalidSession
        case invalidUserID
        case userUnavailable
    }

    private let id = UUID()
    private var revision: UInt64 = 0
    private var records: [String: UserRecord] = [:]
    private var deletedIDs: Set<String> = []
    private let changeSubject = PassthroughSubject<Change, Never>()

    private(set) var isActive = true

    var changes: AnyPublisher<Change, Never> {
        changeSubject.eraseToAnyPublisher()
    }

    func record(for value: UserDto) throws -> UserRecord {
        guard isActive else { throw StoreError.invalidSession }
        guard let id = value.id, !id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw StoreError.invalidUserID
        }

        if let record = records[id] {
            return record
        }

        let record = UserRecord(id: id, value: deletedIDs.contains(id) ? nil : value)
        records[id] = record

        return record
    }

    func beginRequest() throws -> RequestToken {
        guard isActive else { throw StoreError.invalidSession }

        revision += 1

        return RequestToken(storeID: id, revision: revision)
    }

    @discardableResult
    func merge(_ value: UserDto, token: RequestToken) throws -> UserRecord {
        guard isActive, token.storeID == id else { throw StoreError.invalidSession }

        let record = try record(for: value)
        guard !deletedIDs.contains(record.id) else { throw StoreError.userUnavailable }

        if record.replace(with: value, revision: token.revision) {
            changeSubject.send(.updated(value))
        }

        return record
    }

    func receive(_ message: OutboundWebSocketMessage) throws {
        guard isActive else { throw StoreError.invalidSession }

        switch message {
        case let .userUpdatedMessage(message):
            guard let value = message.data else { return }

            try merge(value, token: beginRequest())

        case let .userDeletedMessage(message):
            guard let id = message.data else { return }

            delete(id: id)

        default:
            break
        }
    }

    func delete(id: String) {
        guard isActive,
              !id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              deletedIDs.insert(id).inserted else { return }

        records[id]?.invalidate()
        changeSubject.send(.deleted(id))
    }

    func invalidate() {
        guard isActive else { return }

        isActive = false
        records.values.forEach { $0.invalidate() }
        records.removeAll()
        changeSubject.send(completion: .finished)
    }
}
