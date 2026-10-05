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

    func send<Value: Decodable & Sendable>(_ request: Request<Value>) async throws -> (value: Value, items: [ItemRecord]) {
        let token = try items.beginRequest()
        let response = try await client.send(request)
        try items.validate(token)
        let records = try receiveItems(response, token: token)
        // Keep merged records alive until the caller takes ownership.
        return (response.value, records)
    }

    func send(_ request: Request<Void>) async throws {
        let token = try items.beginRequest()
        try await client.send(request)
        try items.validate(token)
    }

    private func receiveItems(_ response: Response<some Any>, token: ItemStore.RequestToken) throws -> [ItemRecord] {
        let patches: [ItemPatch]
        if let value = response.value as? BaseItemDto {
            patches = try [ItemPatch.item(from: response.map { _ in value })]
        } else if let value = response.value as? BaseItemDtoQueryResult {
            patches = try ItemPatch.items(from: response.map { _ in value })
        } else if let value = response.value as? [BaseItemDto] {
            patches = try ItemPatch.items(from: response.map { _ in value })
        } else if let sessions = response.value as? [SessionInfoDto] {
            patches = try ItemPatch.sessionItems(from: response.map { _ in sessions })
        } else {
            return []
        }
        return try patches.compactMap { patch in
            guard patch.value.id?.nilIfBlank != nil else { return nil }

            return try items.merge(patch, token: token)
        }
    }

    func receiveSessionItems(_ sessions: [SessionInfoDto]) throws -> [ItemRecord] {
        let token = try items.beginRequest()
        return try sessions.compactMap { session in
            guard let item = session.nowPlayingItem, item.id?.nilIfBlank != nil else { return nil }

            return try items.merge(ItemPatch.snapshot(item.withoutUserData), token: token)
        }
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
