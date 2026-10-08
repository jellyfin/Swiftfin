//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import Get
import JellyfinAPI

@MainActor
extension UserSession {

    func send<Value: Decodable & Sendable>(
        _ request: Request<Value>
    ) async throws -> (value: Value, items: [ItemRecord]) {
        try await send(request, itemScope: .partial)
    }

    /// Treats the returned item as the source of truth for all of its fields.
    func sendFullItem(_ request: Request<BaseItemDto>) async throws -> BaseItemDto {
        let response = try await send(request, itemScope: .fullItem)
        return response.value
    }

    private func send<Value: Decodable & Sendable>(
        _ request: Request<Value>,
        itemScope: ItemPatch.Scope
    ) async throws -> (value: Value, items: [ItemRecord]) {
        let token = try items.beginRequest()
        let response = try await client.send(request)
        try items.validate()

        let records: [ItemRecord]
        if let provider = response.value as? any BaseItemPatchProvider {
            let object = try JSONSerialization.jsonObject(with: response.data)
            let patches = try provider.patches(from: object, scope: itemScope)
            records = try patches.compactMap { try items.merge($0, token: token) }
        } else {
            records = []
        }

        // Keep merged records alive until the caller takes ownership.
        return (response.value, records)
    }

    func send(_ request: Request<Void>) async throws {
        try items.validate()
        try await client.send(request)
        try items.validate()
    }

    func receiveSessionItems(_ sessions: [SessionInfoDto]) throws -> [ItemRecord] {
        let token = try items.beginRequest()
        let patches = try sessions.patches()
        return try patches.compactMap { try items.merge($0, token: token) }
    }

    func setFavorite(_ entry: ItemEntry, to isFavorite: Bool) async throws {
        try await updateUserData(entry, field: \.isFavorite, to: isFavorite) {
            isFavorite
                ? Paths.markFavoriteItem(itemID: entry.itemID, userID: self.user.id)
                : Paths.unmarkFavoriteItem(itemID: entry.itemID, userID: self.user.id)
        }
    }

    func setPlayed(_ entry: ItemEntry, to isPlayed: Bool) async throws {
        try await updateUserData(entry, field: \.isPlayed, to: isPlayed) {
            isPlayed
                ? Paths.markPlayedItem(itemID: entry.itemID, userID: self.user.id)
                : Paths.markUnplayedItem(itemID: entry.itemID, userID: self.user.id)
        }
    }

    private func updateUserData(
        _ entry: ItemEntry,
        field: ItemUserDataField,
        to value: Bool,
        request: @escaping () -> Request<UserItemDataDto>
    ) async throws {
        try await items.mutateUserData(entry.item, field: field, to: value) {
            let response = try await self.client.send(request())
            let object = try JSONSerialization.jsonObject(with: response.data) as? [String: Any] ?? [:]
            return (response.value, Set(object.keys))
        }
    }
}
