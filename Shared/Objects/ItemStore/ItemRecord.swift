//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import Observation

/// Identifies a server item within its owning store.
struct ItemKey: Hashable, Sendable {

    let itemID: String
}

/// Selects a Boolean user-data field for an optimistic update.
typealias ItemUserDataField = WritableKeyPath<UserItemDataDto, Bool?>

/// Holds observable item data shared by views and collections in one session.
@MainActor
@Observable
final class ItemRecord: Identifiable {

    nonisolated let id: ItemKey
    private var metadata: BaseItemDto?
    private var currentProgram: ItemRecord?
    /// An optimistic change shows a requested value before server confirmation and rolls back if the request fails.
    private var optimisticChanges: [(id: UUID, field: ItemUserDataField, value: Bool)] = []

    @ObservationIgnored
    private var metadataRevisions = FieldRevisions()
    @ObservationIgnored
    private var userDataRevisions = FieldRevisions()
    @ObservationIgnored
    private var programRevision: UInt64 = 0

    var value: BaseItemDto? {
        guard var value = metadata else { return nil }

        if let currentProgram {
            value.currentProgram = currentProgram.value
        }

        if optimisticChanges.isNotEmpty {
            var data = value.userData ?? UserItemDataDto(key: id.itemID)

            for change in optimisticChanges {
                data[keyPath: change.field] = change.value
            }

            value.userData = data
        }

        return value
    }

    var confirmedUserData: UserItemDataDto? {
        metadata?.userData
    }

    func beginChange(
        id: UUID,
        field: ItemUserDataField,
        value: Bool
    ) {
        optimisticChanges.append((id, field, value))
    }

    func endChange(id: UUID) {
        optimisticChanges.removeAll { $0.id == id }
    }

    /// Stored records start empty; presentation fallbacks may start with a local snapshot.
    init(id: ItemKey, presentationValue: BaseItemDto? = nil) {
        self.id = id
        self.metadata = presentationValue.map(Self.withoutPlaylistOccurrences)
    }

    @discardableResult
    func merge(
        _ patch: ItemPatch,
        revision: UInt64,
        program: ItemRecord?
    ) throws -> ItemStore.Update {
        let previous = metadata ?? BaseItemDto(id: id.itemID)
        var previousMetadata = previous
        previousMetadata.userData = nil

        let excluded: Set<String> = ["Id", "UserData", "CurrentProgram", "PlaylistItemId"]
        let metadataFields = patch.fields.subtracting(excluded)
        var metadataRevisions = self.metadataRevisions
        var value = previous

        if metadataFields.isNotEmpty || patch.scope != .partial {
            var incomingMetadata = patch.value
            incomingMetadata.userData = nil
            incomingMetadata.currentProgram = nil
            incomingMetadata.playlistItemID = nil

            let incoming = try JSONSerialization.encode(incomingMetadata).filter { !excluded.contains($0.key) }
            let existing = try JSONSerialization.encode(previousMetadata).filter { !excluded.contains($0.key) }
            var merged = metadataRevisions.merge(
                existing,
                with: incoming,
                presentFields: metadataFields,
                revision: revision,
                replacing: patch.scope != .partial
            )

            merged["Id"] = id.itemID
            value = try JSONSerialization.decode(BaseItemDto.self, from: merged)
            value.userData = previous.userData
        }

        var userDataRevisions = self.userDataRevisions

        if patch.scope == .fullItem || (patch.scope == .partial && patch.fields.contains("UserData")) {
            if let incoming = patch.value.userData {
                if userDataRevisions.accepts(revision) {
                    let existing = try JSONSerialization.encode(previous.userData ?? UserItemDataDto(key: incoming.key))
                    let merged = try userDataRevisions.merge(
                        existing,
                        with: JSONSerialization.encode(incoming),
                        presentFields: patch.userDataFields,
                        revision: revision,
                        replacing: patch.scope == .fullItem
                    )

                    value.userData = try JSONSerialization.decode(UserItemDataDto.self, from: merged)
                    value.userData?.itemID = id.itemID
                }
            } else if revision >= userDataRevisions.latest {
                value.userData = nil
                userDataRevisions.clear(at: revision)
            }
        }

        let previousProgramID = currentProgram?.id
        if (patch.scope == .fullItem || (patch.scope == .partial && patch.fields.contains("CurrentProgram"))) && revision >=
            programRevision
        {
            currentProgram = program?.references(self) == true ? nil : program
            programRevision = revision
        }

        self.metadataRevisions = metadataRevisions
        self.userDataRevisions = userDataRevisions

        var updatedMetadata = value
        updatedMetadata.userData = nil

        let update = ItemStore.Update(
            itemID: id.itemID,
            metadataChanged: previousMetadata != updatedMetadata || previousProgramID != currentProgram?.id,
            userDataChanged: previous.userData != value.userData
        )

        if value != metadata {
            metadata = value
        }

        return update
    }

    func invalidate() {
        metadata = nil
        currentProgram = nil
        metadataRevisions = .init()
        userDataRevisions = .init()
        programRevision = 0
        optimisticChanges.removeAll()
    }

    private func references(_ record: ItemRecord) -> Bool {
        self === record || currentProgram?.references(record) == true
    }

    private static func withoutPlaylistOccurrences(_ item: BaseItemDto) -> BaseItemDto {
        var item = item
        item.playlistItemID = nil
        item.currentProgram = item.currentProgram.map(withoutPlaylistOccurrences)
        return item
    }
}
