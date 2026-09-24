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

/// Keeps newly received records alive until the receiving feature takes ownership.
struct ItemStoreResponse<Value: Sendable>: Sendable {
    let value: Value
    let items: [ItemRecord]
}

extension UserSession {

    @MainActor
    func send<Value: Decodable & Sendable>(_ request: Request<Value>) async throws -> ItemStoreResponse<Value> {
        let token = try items.beginRequest()
        let response = try await client.send(request)
        try items.validate(token)
        let records = try items.receive(response, token: token)
        return ItemStoreResponse(value: response.value, items: records)
    }

    @MainActor
    func send(_ request: Request<Void>) async throws {
        let token = try items.beginRequest()
        try await client.send(request)
        try items.validate(token)
    }
}

extension ItemStore {

    func receive(_ response: Response<some Any>, token: RequestToken) throws -> [ItemRecord] {
        let patches: [ItemPatch]
        if let value = response.value as? BaseItemDto {
            patches = try [ItemPatch(response: response.map { _ in value })]
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
            return try merge(patch, token: token)
        }
    }

    func receiveSessionItems(_ sessions: [SessionInfoDto]) throws -> [ItemRecord] {
        let token = try beginRequest()
        return try sessions.compactMap { session in
            guard let item = session.nowPlayingItem, item.id?.nilIfBlank != nil else { return nil }
            return try merge(ItemPatch(value: item.withoutUserData), token: token)
        }
    }

    func setFavorite(_ entry: ItemEntry, to isFavorite: Bool, userSession: UserSession) async throws {
        try await updateUserData(entry, field: \.isFavorite, to: isFavorite, userSession: userSession) {
            isFavorite
                ? Paths.markFavoriteItem(itemID: entry.itemID, userID: userSession.user.id)
                : Paths.unmarkFavoriteItem(itemID: entry.itemID, userID: userSession.user.id)
        }
    }

    func setPlayed(_ entry: ItemEntry, to isPlayed: Bool, userSession: UserSession) async throws {
        try await updateUserData(entry, field: \.isPlayed, to: isPlayed, userSession: userSession) {
            isPlayed
                ? Paths.markPlayedItem(itemID: entry.itemID, userID: userSession.user.id)
                : Paths.markUnplayedItem(itemID: entry.itemID, userID: userSession.user.id)
        }
    }

    private func updateUserData(
        _ entry: ItemEntry,
        field: ItemUserDataField,
        to value: Bool,
        userSession: UserSession,
        request: @escaping () -> Request<UserItemDataDto>
    ) async throws {
        guard userSession.items === self, entry.id.item.sessionID == sessionID, entry.value != nil else {
            throw StoreError.itemUnavailable
        }
        try await mutateUserData(entry, field: field, to: value) {
            let response = try await userSession.client.send(request())
            let object = try JSONSerialization.jsonObject(with: response.data) as? [String: Any] ?? [:]
            return ItemUserDataPatch(value: response.value, fields: Set(object.keys))
        }
    }
}
