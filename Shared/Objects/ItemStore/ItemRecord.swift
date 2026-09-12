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

struct ItemKey: Hashable, Sendable {
    let sessionID: UUID
    let itemID: String
}

typealias ItemUserDataField = WritableKeyPath<UserItemDataDto, Bool?>

/// The only retained copy of an item's metadata in a user session.
@MainActor
@Observable
final class ItemRecord: Identifiable {

    nonisolated let id: ItemKey
    private var metadata: BaseItemDto?
    private var currentProgram: ItemRecord?
    private var optimisticChanges: [(id: UUID, field: ItemUserDataField, value: Bool)] = []

    @ObservationIgnored
    private var metadataRevisions = FieldRevisions()
    @ObservationIgnored
    private var userDataRevisions = FieldRevisions()
    @ObservationIgnored
    private var programRevision: UInt64 = 0

    var value: BaseItemDto? {
        guard var value = metadata else { return nil }
        value.currentProgram = currentProgram?.value
        if !optimisticChanges.isEmpty {
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

    func beginChange(id: UUID, field: ItemUserDataField, value: Bool) {
        optimisticChanges.append((id, field, value))
    }

    func endChange(id: UUID) {
        optimisticChanges.removeAll { $0.id == id }
    }

    init(id: ItemKey) {
        self.id = id
    }

    /// Section headings and previews have no server identity. Their DTO must keep its nil ID.
    init(presentation value: BaseItemDto) {
        self.id = ItemKey(sessionID: UUID(), itemID: value.id ?? UUID().uuidString)
        self.metadata = value
        self.metadata?.playlistItemID = nil
        self.metadata?.currentProgram = nil
        self.currentProgram = value.currentProgram.map { ItemRecord(presentation: $0) }
    }

    @discardableResult
    func merge(_ patch: ItemPatch, revision: UInt64, program: ItemRecord?) throws -> ItemStore.Update {
        let previous = metadata ?? BaseItemDto(id: id.itemID)
        var previousMetadata = previous
        previousMetadata.userData = nil
        // Identity, user data, and related/occurrence records have separate ownership.
        let excluded: Set<String> = ["Id", "UserData", "CurrentProgram", "PlaylistItemId"]
        let metadataFields = patch.fields.subtracting(excluded)
        var metadataRevisions = self.metadataRevisions
        var value = previous
        // Playback updates only need to merge user data, even for a large retained item.
        if !metadataFields.isEmpty || patch.replacesMetadata {
            var incomingMetadata = patch.value
            incomingMetadata.userData = nil
            incomingMetadata.currentProgram = nil
            incomingMetadata.playlistItemID = nil
            let incoming = try CodableFields.encode(incomingMetadata).filter { !excluded.contains($0.key) }
            let existing = try CodableFields.encode(previousMetadata).filter { !excluded.contains($0.key) }
            var merged = metadataRevisions.merge(
                existing,
                with: incoming,
                presentFields: metadataFields,
                revision: revision,
                replacing: patch.replacesMetadata
            )
            merged["Id"] = id.itemID
            value = try CodableFields.decode(BaseItemDto.self, from: merged)
            value.userData = previous.userData
        }

        var userDataRevisions = self.userDataRevisions
        if !patch.replacesMetadata, patch.fields.contains("UserData") {
            if let incoming = patch.value.userData {
                if userDataRevisions.accepts(revision) {
                    let existing = try CodableFields.encode(previous.userData ?? UserItemDataDto(key: incoming.key))
                    let merged = try userDataRevisions.merge(
                        existing,
                        with: CodableFields.encode(incoming),
                        presentFields: patch.userDataFields,
                        revision: revision
                    )
                    value.userData = try CodableFields.decode(UserItemDataDto.self, from: merged)
                    value.userData?.itemID = id.itemID
                }
            } else if revision >= userDataRevisions.latest {
                value.userData = nil
                userDataRevisions.clear(at: revision)
            }
        }

        let previousProgramID = currentProgram?.id
        if !patch.replacesMetadata, patch.fields.contains("CurrentProgram"), revision >= programRevision {
            currentProgram = program?.references(self) == true ? nil : program
            programRevision = revision
        }
        // Commit revision state only after the merged values decode successfully.
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
}

/// The decoded DTO plus the fields actually present on the wire, including nulls.
struct ItemPatch {
    let value: BaseItemDto
    let fields: Set<String>
    let userDataFields: Set<String>
    let program: [String: Any]?
    let replacesMetadata: Bool

    init(value: BaseItemDto, object: [String: Any], replacesMetadata: Bool = false) {
        self.value = value
        self.replacesMetadata = replacesMetadata
        self.fields = Set(object.keys)
        self.userDataFields = Set((object["UserData"] as? [String: Any] ?? [:]).keys)
        self.program = object["CurrentProgram"] as? [String: Any]
    }

    init(value: BaseItemDto, replacesMetadata: Bool = false) throws {
        try self.init(value: value, object: CodableFields.encode(value), replacesMetadata: replacesMetadata)
    }
}

/// User-data actions also distinguish an omitted field from an explicit null.
struct ItemUserDataPatch {
    var value: UserItemDataDto
    let fields: Set<String>

    init(value: UserItemDataDto, fields: Set<String>) {
        self.value = value
        self.fields = fields
    }

    init(value: UserItemDataDto) throws {
        try self.init(value: value, fields: Set(CodableFields.encode(value).keys))
    }
}
