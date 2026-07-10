//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Factory
import Foundation
import JellyfinAPI
import TVServices

@MainActor
struct TopShelfPublisher {

    func publish() async {
        guard let session = Container.shared.userSessionManager().currentSession else {
            clear()
            return
        }

        do {
            let items = try await resumeItems(session: session)
            let payload = TopShelfPayload(
                sections: [
                    .init(
                        title: "Continue Watching",
                        items: items.compactMap { payloadItem(for: $0, session: session) }
                    ),
                ]
            )

            try save(payload)
            TVTopShelfContentProvider.topShelfContentDidChange()
        } catch {
            clear()
        }
    }

    private func resumeItems(session: UserSession) async throws -> [BaseItemDto] {
        var parameters = Paths.GetResumeItemsParameters()
        parameters.enableUserData = true
        parameters.fields = .MinimumFields
        parameters.limit = 12
        parameters.mediaTypes = [.video]

        let response = try await session.client.send(Paths.getResumeItems(parameters: parameters))
        return response.value.items ?? []
    }

    private func payloadItem(for item: BaseItemDto, session: UserSession) -> TopShelfItemPayload? {
        guard let itemID = item.id,
              let actionURL = URL(string: "guamaflix://\(session.server.id)/\(session.user.id)/item/\(itemID)") else { return nil }

        let imageURL = item
            .landscapeImageSources(maxWidth: 720, quality: 90)
            .compactMap(\.url)
            .first

        return TopShelfItemPayload(
            id: itemID,
            title: item.displayTitle,
            subtitle: item.subtitle ?? item.progressLabel,
            imageURL: imageURL,
            actionURL: actionURL,
            playbackProgress: playbackProgress(for: item)
        )
    }

    private func playbackProgress(for item: BaseItemDto) -> Double? {
        guard let playedPercentage = item.userData?.playedPercentage else { return nil }
        return min(max(playedPercentage / 100, 0), 1)
    }

    private func save(_ payload: TopShelfPayload) throws {
        let data = try JSONEncoder().encode(payload)
        try FileManager.default.createDirectory(
            at: TopShelfStorage.url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try data.write(to: TopShelfStorage.url, options: .atomic)
    }

    private func clear() {
        try? FileManager.default.removeItem(at: TopShelfStorage.url)
        TVTopShelfContentProvider.topShelfContentDidChange()
    }
}

private struct TopShelfPayload: Codable {

    let sections: [TopShelfSection]
}

private struct TopShelfSection: Codable {

    let title: String
    let items: [TopShelfItemPayload]
}

private struct TopShelfItemPayload: Codable {

    let id: String
    let title: String
    let subtitle: String?
    let imageURL: URL?
    let actionURL: URL
    let playbackProgress: Double?
}

private enum TopShelfStorage {

    static var url: URL {
        if let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.dev.guama.guamaflix"
        ) {
            return containerURL.appendingPathComponent("TopShelf.json")
        }

        return FileManager.default.temporaryDirectory.appendingPathComponent("TopShelf.json")
    }
}
