//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Factory
import JellyfinAPI
import UIKit

// TODO: preload adjacent images
// TODO: don't just select first trickplayinfo

class TrickplayPreviewImageProvider: PreviewImageProvider {

    private struct TrickplayImage {

        let image: UIImage
        let secondsRange: ClosedRange<Duration>

        let columns: Int
        let rows: Int
        let tileInterval: Duration

        func tile(for seconds: Duration) -> UIImage? {
            guard secondsRange.contains(seconds) else {
                return nil
            }

            let index = Int(((seconds - secondsRange.lowerBound) / tileInterval).rounded(.down))
            let tileImage = image.getTileImage(columns: columns, rows: rows, index: index)
            return tileImage
        }
    }

    private let info: TrickplayInfoDto
    private let itemID: String
    private let mediaSourceID: String
    private let runtime: Duration

    @MainActor
    private var imageTasks: [Int: Task<TrickplayImage?, Never>] = [:]

    init(
        info: TrickplayInfoDto,
        itemID: String,
        mediaSourceID: String,
        runtime: Duration
    ) {
        self.info = info
        self.itemID = itemID
        self.mediaSourceID = mediaSourceID
        self.runtime = runtime
    }

    func imageIndex(for seconds: Duration) -> Int? {
        let intervalIndex = Int(seconds / Duration.milliseconds(info.interval ?? 1000))
        return intervalIndex
    }

    @MainActor
    func image(for seconds: Duration) async -> UIImage? {
        let rows = info.tileHeight ?? 0
        let columns = info.tileWidth ?? 0
        let area = rows * columns
        let intervalIndex = Int(seconds / Duration.milliseconds(info.interval ?? 1000))
        let imageIndex = intervalIndex / area

        if let task = imageTasks[imageIndex] {
            guard let image = await task.value else { return nil }
            return image.tile(for: seconds)
        }

        let interval = info.interval ?? 0
        let tileImageDuration = Duration.milliseconds(
            Double(interval * rows * columns)
        )
        let tileInterval = Duration.milliseconds(interval)

        let currentImageTask = task(
            imageIndex: imageIndex,
            tileImageDuration: tileImageDuration,
            columns: columns,
            rows: rows,
            tileInterval: tileInterval
        )

        if imageIndex > 1, !imageTasks.keys.contains(imageIndex - 1) {
            let previousIndexTask = task(
                imageIndex: imageIndex - 1,
                tileImageDuration: tileImageDuration,
                columns: columns,
                rows: rows,
                tileInterval: tileInterval
            )
            imageTasks[imageIndex - 1] = previousIndexTask
        }

        if seconds < (runtime - tileImageDuration), !imageTasks.keys.contains(imageIndex + 1) {
            let nextIndexTask = task(
                imageIndex: imageIndex + 1,
                tileImageDuration: tileImageDuration,
                columns: columns,
                rows: rows,
                tileInterval: tileInterval
            )
            imageTasks[imageIndex + 1] = nextIndexTask
        }

        imageTasks[imageIndex] = currentImageTask

        guard let image = await currentImageTask.value else { return nil }
        return image.tile(for: seconds)
    }

    private func task(
        imageIndex: Int,
        tileImageDuration: Duration,
        columns: Int,
        rows: Int,
        tileInterval: Duration
    ) -> Task<TrickplayImage?, Never> {
        Task<TrickplayImage?, Never> { [weak self] () -> TrickplayImage? in
            guard let tileWidth = self?.info.width else { return nil }
            guard let itemID = self?.itemID else { return nil }

            let client = Container.shared.currentUserSession()!.client
            let request = Paths.getTrickplayTileImage(
                itemID: itemID,
                width: tileWidth,
                index: imageIndex
            )
            guard let response = try? await client.send(request) else { return nil }
            guard let image = UIImage(data: response.value) else { return nil }

            let secondsRangeStart = tileImageDuration * Double(imageIndex)
            let secondsRangeEnd = secondsRangeStart + tileImageDuration

            let trickplayImage = TrickplayImage(
                image: image,
                secondsRange: secondsRangeStart ... secondsRangeEnd,
                columns: columns,
                rows: rows,
                tileInterval: tileInterval
            )

            return trickplayImage
        }
    }
}
