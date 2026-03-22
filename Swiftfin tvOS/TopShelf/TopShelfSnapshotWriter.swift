//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import TVServices
import UIKit

enum TopShelfSnapshotWriter {

    private static let maxItems = 4
    private static let stateLock = NSLock()
    private static var updateTask: Task<Void, Never>?

    static func update(
        with items: [BaseItemDto],
        userSession: UserSession
    ) {
        let snapshotSourceItems = Array(items.prefix(maxItems))

        cancelInFlightUpdate()

        let task = Task(priority: .utility) {
            let snapshotItems = await buildSnapshotItems(
                from: snapshotSourceItems,
                userSession: userSession
            )

            guard !Task.isCancelled else { return }

            let snapshot = TopShelfSnapshot(
                generatedAt: .now,
                sectionTitle: L10n.resume,
                userID: userSession.user.id,
                items: snapshotItems
            )

            do {
                try TopShelfSnapshotStore.pruneCachedImages(
                    keeping: snapshotItems.map(\.id)
                )
                try TopShelfSnapshotStore.save(snapshot)
                #if DEBUG
                NSLog(
                    "TopShelf: prepared snapshot from %ld resume items, %ld renderable items",
                    items.count,
                    snapshotItems.count
                )
                #endif
            } catch {
                #if DEBUG
                NSLog("TopShelf: failed to save snapshot: %@", error.localizedDescription)
                #endif
            }

            guard !Task.isCancelled else { return }

            TVTopShelfContentProvider.topShelfContentDidChange()
        }

        stateLock.lock()
        updateTask = task
        stateLock.unlock()
    }

    static func clear() {
        cancelInFlightUpdate()

        do {
            try TopShelfSnapshotStore.clear()
        } catch {
            #if DEBUG
            NSLog("TopShelf: failed to clear snapshot: %@", error.localizedDescription)
            #endif
        }

        TVTopShelfContentProvider.topShelfContentDidChange()
    }

    private static func buildSnapshotItems(
        from items: [BaseItemDto],
        userSession: UserSession
    ) async -> [TopShelfSnapshot.Item] {
        var snapshotItems: [TopShelfSnapshot.Item] = []

        for item in items {
            guard !Task.isCancelled else { return snapshotItems }

            if let snapshotItem = await item.topShelfSnapshotItem(userSession: userSession) {
                snapshotItems.append(snapshotItem)
            }
        }

        return snapshotItems
    }

    private static func cancelInFlightUpdate() {
        stateLock.lock()
        let task = updateTask
        updateTask = nil
        stateLock.unlock()

        task?.cancel()
    }
}

private extension BaseItemDto {

    func topShelfSnapshotItem(
        userSession: UserSession
    ) async -> TopShelfSnapshot.Item? {
        guard let id,
              let remoteImageURL = topShelfImageURL(client: userSession.client)
        else { return nil }

        let imageURL = await topShelfCachedImageURL(
            from: remoteImageURL,
            itemID: id
        ) ?? remoteImageURL

        let normalizedProgress = clamp(
            (userData?.playedPercentage ?? 0) / 100,
            min: 0,
            max: 1
        )

        return .init(
            id: id,
            title: topShelfTitle,
            imageURL: imageURL,
            playbackProgress: normalizedProgress,
            displayURL: TopShelfDeepLink(
                action: .display,
                itemID: id,
                userID: userSession.user.id
            ).url,
            playURL: TopShelfDeepLink(
                action: .play,
                itemID: id,
                userID: userSession.user.id
            ).url
        )
    }

    var topShelfTitle: String {
        switch type {
        case .episode:
            switch (seriesName, seasonEpisodeLabel) {
            case let (seriesName?, seasonEpisodeLabel?):
                "\(seriesName) • \(seasonEpisodeLabel)"
            case let (seriesName?, nil):
                seriesName
            default:
                displayTitle
            }
        default:
            displayTitle
        }
    }

    func topShelfImageURL(client: JellyfinClient) -> URL? {
        let imageWidth = UIScreen.main.scale(
            TVTopShelfSectionedContent.imageSize(for: .hdtv).width
        )

        for candidate in topShelfImageCandidates {
            guard let itemID = candidate.itemID,
                  itemID.isNotEmpty,
                  let tag = candidate.tag,
                  tag.isNotEmpty
            else {
                continue
            }

            let parameters = Paths.GetItemImageParameters(
                maxWidth: imageWidth,
                quality: 90,
                tag: tag
            )

            let request = Paths.getItemImage(
                itemID: itemID,
                imageType: candidate.type.rawValue,
                parameters: parameters
            )

            if let url = client.fullURL(with: request, queryAPIKey: true) {
                return url
            }
        }

        return nil
    }

    var topShelfImageCandidates: [(itemID: String?, type: ImageType, tag: String?)] {
        switch type {
        case .episode:
            [
                (parentBackdropItemID, .backdrop, parentBackdropImageTags?.first),
                (seriesID, .thumb, seriesThumbImageTag),
                (id, .primary, imageTags?[ImageType.primary.rawValue]),
                (seriesID, .primary, seriesPrimaryImageTag),
                (id, .thumb, imageTags?[ImageType.thumb.rawValue]),
            ]
        case .video:
            if extraType != nil {
                [
                    (parentBackdropItemID, .backdrop, parentBackdropImageTags?.first),
                    (id, .primary, imageTags?[ImageType.primary.rawValue]),
                    (id, .thumb, imageTags?[ImageType.thumb.rawValue]),
                ]
            } else {
                [
                    (id, .primary, imageTags?[ImageType.primary.rawValue]),
                    (id, .thumb, imageTags?[ImageType.thumb.rawValue]),
                    (id, .backdrop, backdropImageTags?.first),
                ]
            }
        default:
            [
                (id, .thumb, imageTags?[ImageType.thumb.rawValue]),
                (id, .backdrop, backdropImageTags?.first),
                (id, .primary, imageTags?[ImageType.primary.rawValue]),
            ]
        }
    }

    func topShelfCachedImageURL(
        from sourceURL: URL,
        itemID: String
    ) async -> URL? {
        do {
            let (data, response) = try await URLSession.shared.data(from: sourceURL)

            guard !Task.isCancelled else { return nil }
            guard let image = UIImage(data: data) else {
                #if DEBUG
                NSLog("TopShelf: downloaded image for %@ could not be decoded", itemID)
                #endif
                return nil
            }

            let imageSize = TVTopShelfSectionedContent.imageSize(for: .hdtv)
            let targetSize = CGSize(
                width: UIScreen.main.scale(imageSize.width),
                height: UIScreen.main.scale(imageSize.height)
            )

            let cachedImage = image.preparingThumbnail(of: targetSize) ?? image
            let cachedImageData = cachedImage.jpegData(compressionQuality: 0.85) ?? data
            let pathExtension = response.mimeType.flatMap(topShelfImagePathExtension) ?? "jpg"

            return try TopShelfSnapshotStore.cacheImageData(
                cachedImageData,
                for: itemID,
                pathExtension: pathExtension
            )
        } catch is CancellationError {
            return nil
        } catch {
            #if DEBUG
            NSLog(
                "TopShelf: failed to cache image for %@: %@",
                itemID,
                error.localizedDescription
            )
            #endif
            return nil
        }
    }

    func topShelfImagePathExtension(from mimeType: String) -> String? {
        switch mimeType.lowercased() {
        case "image/jpeg", "image/jpg":
            "jpg"
        case "image/png":
            "png"
        case "image/webp":
            "webp"
        default:
            nil
        }
    }
}
