//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import TVServices

final class TopShelfContentProvider: TVTopShelfContentProvider {

    override func loadTopShelfContent() async -> (any TVTopShelfContent)? {
        do {
            guard let snapshot = try TopShelfSnapshotStore.load(),
                  !snapshot.items.isEmpty
            else {
                #if DEBUG
                NSLog("TopShelf: no snapshot content available for extension")
                #endif
                return nil
            }

            let items = snapshot.items.map(makeSectionedItem)

            guard !items.isEmpty else {
                #if DEBUG
                NSLog("TopShelf: snapshot was loaded but contained no renderable items")
                #endif
                return nil
            }

            let collection = TVTopShelfItemCollection(items: items)
            collection.title = snapshot.sectionTitle

            #if DEBUG
            NSLog("TopShelf: extension returning %ld items", items.count)
            #endif
            return
                TVTopShelfSectionedContent(sections: [collection])
        } catch {
            #if DEBUG
            NSLog("TopShelf: extension failed to load content: %@", error.localizedDescription)
            #endif
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
