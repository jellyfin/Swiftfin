//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import Logging
import TVServices

final class TopShelfContentProvider: TVTopShelfContentProvider {

    private let logger = Logger(label: "org.jellyfin.swiftfin")

    override func loadTopShelfContent() async -> (any TVTopShelfContent)? {
        do {
            guard let snapshot = try TopShelfSnapshotStore.load(),
                  !snapshot.items.isEmpty
            else {
                logger.debug("No top shelf snapshot content available")
                return nil
            }

            let items = snapshot.items.map(makeSectionedItem)
            let collection = TVTopShelfItemCollection(items: items)
            collection.title = snapshot.sectionTitle

            logger.debug("Returning \(items.count) top shelf items")

            return TVTopShelfSectionedContent(sections: [collection])
        } catch {
            logger.error("Failed to load top shelf content: \(error.localizedDescription)")
            return nil
        }
    }

    private func makeSectionedItem(
        from item: TopShelfSnapshot.Item
    ) -> TVTopShelfSectionedItem {
        let topShelfItem = TVTopShelfSectionedItem(identifier: item.id)
        topShelfItem.title = item.title
        topShelfItem.imageShape = .hdtv
        topShelfItem.playbackProgress = item.playbackProgress
        topShelfItem.displayAction = TVTopShelfAction(url: item.displayURL)
        topShelfItem.playAction = TVTopShelfAction(url: item.playURL)
        topShelfItem.setImageURL(
            item.imageURL,
            for: [
                .screenScale1x,
                .screenScale2x,
            ]
        )

        return topShelfItem
    }
}
