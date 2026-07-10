//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import TVServices

final class ContentProvider: TVTopShelfContentProvider {

    override func loadTopShelfContent() async -> (any TVTopShelfContent)? {
        guard let payload = TopShelfPayload.load(), !payload.sections.isEmpty else { return nil }

        let sections = payload.sections.compactMap { section -> TVTopShelfItemCollection<TVTopShelfSectionedItem>? in
            let items = section.items.map(\.topShelfItem)
            guard !items.isEmpty else { return nil }

            let collection = TVTopShelfItemCollection(items: items)
            collection.title = section.title
            return collection
        }

        guard !sections.isEmpty else { return nil }

        return TVTopShelfSectionedContent(sections: sections)
    }
}

private struct TopShelfPayload: Codable {

    var sections: [TopShelfSection]

    static func load() -> TopShelfPayload? {
        guard let data = try? Data(contentsOf: TopShelfStorage.url) else { return nil }
        return try? JSONDecoder().decode(TopShelfPayload.self, from: data)
    }
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

    var topShelfItem: TVTopShelfSectionedItem {
        let item = TVTopShelfSectionedItem(identifier: id)
        item.title = subtitle.map { "\(title) - \($0)" } ?? title
        item.displayAction = TVTopShelfAction(url: actionURL)
        item.imageShape = .hdtv

        if let playbackProgress {
            item.playbackProgress = playbackProgress
        }

        if let imageURL {
            item.setImageURL(imageURL, for: [.screenScale1x, .screenScale2x])
        }

        return item
    }
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
