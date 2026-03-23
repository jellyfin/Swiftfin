//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Factory
import JellyfinAPI
import Logging
import Nuke
import TVServices
import UIKit

enum TopShelfSnapshotWriter {

    fileprivate static let logger = Logger(label: "org.jellyfin.swiftfin")
    private static let maxItems = 4
    private static let stateLock = NSLock()
    private static var updateTask: Task<Void, Never>?

    static func update(
        with items: [BaseItemDto]
    ) {
        let snapshotSourceItems = Array(items.prefix(maxItems))

        cancelInFlightUpdate()

        let task = Task(priority: .utility) {
            guard let userSession = Container.shared.currentUserSession() else {
                clearSnapshot(postChangeNotification: true)
                return
            }

            let snapshotItems = await buildSnapshotItems(
                from: snapshotSourceItems,
                userID: userSession.user.id
            )

            guard !Task.isCancelled else { return }

            guard !snapshotItems.isEmpty else {
                clearSnapshot(postChangeNotification: true)
                return
            }

            let snapshot = TopShelfSnapshot(
                generatedAt: .now,
                sectionTitle: L10n.resume,
                userID: userSession.user.id,
                items: snapshotItems
            )

            do {
                try TopShelfSnapshotStore.save(snapshot)
            } catch {
                logger.error("Failed to save top shelf snapshot: \(error.localizedDescription)")
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
        clearSnapshot(postChangeNotification: true)
    }

    private static func buildSnapshotItems(
        from items: [BaseItemDto],
        userID: String
    ) async -> [TopShelfSnapshot.Item] {
        var snapshotItems: [TopShelfSnapshot.Item] = []

        for item in items {
            guard !Task.isCancelled else { return snapshotItems }

            if let snapshotItem = await item.topShelfSnapshotItem(userID: userID) {
                snapshotItems.append(snapshotItem)
            }
        }

        return snapshotItems
    }

    private static func clearSnapshot(postChangeNotification: Bool) {
        do {
            try TopShelfSnapshotStore.clear()

            if let topShelfCache = DataCache.Swiftfin.topShelf {
                topShelfCache.removeAll()
                topShelfCache.flush()
            }
        } catch {
            logger.error("Failed to clear top shelf snapshot: \(error.localizedDescription)")
        }

        if postChangeNotification {
            TVTopShelfContentProvider.topShelfContentDidChange()
        }
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
        userID: String
    ) async -> TopShelfSnapshot.Item? {
        guard let id,
              let imageURL = await topShelfCachedImageURL()
        else { return nil }

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
                userID: userID
            ).url,
            playURL: TopShelfDeepLink(
                action: .play,
                itemID: id,
                userID: userID
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

    func topShelfCachedImageURL() async -> URL? {
        guard let topShelfCache = DataCache.Swiftfin.topShelf else {
            TopShelfSnapshotWriter.logger.warning("Top shelf image cache is unavailable")
            return nil
        }

        let imageSize = TVTopShelfSectionedContent.imageSize(for: .hdtv)
        let imageWidth = imageSize.width
        let screenScale = await MainActor.run { UIScreen.main.nativeScale }
        let targetSize = CGSize(
            width: imageWidth * screenScale,
            height: imageSize.height * screenScale
        )

        for source in landscapeImageSources(maxWidth: imageWidth, quality: 90) {
            guard let sourceURL = source.url else { continue }

            let request = ImageRequest(url: sourceURL)
            let cacheKey = "top-shelf-\(ImagePipeline.Swiftfin.posters.cache.makeDataCacheKey(for: request))"

            if topShelfCache.containsData(for: cacheKey) {
                topShelfCache.flush(for: cacheKey)
                return topShelfCache.url(for: cacheKey)
            }

            do {
                let image = try await ImagePipeline.Swiftfin.posters.image(for: request)

                guard !Task.isCancelled else { return nil }

                let cachedImage = image.preparingThumbnail(of: targetSize) ?? image
                guard let cachedImageData = cachedImage.jpegData(compressionQuality: 0.85) ?? cachedImage.pngData()
                else {
                    continue
                }

                topShelfCache.storeData(cachedImageData, for: cacheKey)
                topShelfCache.flush(for: cacheKey)

                return topShelfCache.url(for: cacheKey)
            } catch is CancellationError {
                return nil
            } catch {
                continue
            }
        }

        TopShelfSnapshotWriter.logger.debug("Unable to resolve a top shelf image for item \(displayTitle)")
        return nil
    }
}
