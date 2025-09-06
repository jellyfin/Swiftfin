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

class TrickplayImageProvider: PreviewImageProvider {

    private struct TrickplayImage {

        let image: UIImage
        let secondsRange: ClosedRange<Duration>

        let columns: Int
        let rows: Int
        let interval: Duration

        func image(for seconds: Duration) -> UIImage? {
            guard secondsRange.contains(seconds) else {
                return nil
            }

            let index = Int(((seconds - secondsRange.lowerBound) / interval).rounded(.down))
            let tileImage = image.getTileImage(columns: columns, rows: rows, index: index)
            return tileImage
        }
    }

    private let info: TrickplayInfo
    private let runtime: Duration
    private let itemID: String
    private let mediaSourceID: String

    @MainActor
    private var images: [Int: TrickplayImage] = [:]
    @MainActor
    private var imageTasks: [Int: Task<UIImage?, Never>] = [:]

    init(
        info: TrickplayInfo,
        itemID: String,
        mediaSourceID: String,
        runtime: Duration
    ) {
        self.info = info
        self.runtime = runtime
        self.itemID = itemID
        self.mediaSourceID = mediaSourceID
    }

    func imageIndex(for seconds: Duration) -> Int {
        let intervalIndex = Int(seconds / Duration.milliseconds(info.interval ?? 1000))
        return intervalIndex
    }

    @MainActor
    func image(for seconds: Duration) async -> UIImage? {
        let rows = info.tileHeight ?? 0
        let columns = info.tileWidth ?? 0
        let area = rows * columns
        let intervalIndex = Int(seconds / Duration.milliseconds(info.interval ?? 1000))
        let tileImageIndex = intervalIndex / area

        if let trickplayImage = images[tileImageIndex] {
            return trickplayImage.image(for: seconds)
        }

        if let task = imageTasks[tileImageIndex] {
            return await task.value
        }

        let interval = info.interval ?? 0
        let tileImageDuration = Duration.milliseconds(
            Double(interval * rows * columns)
        )

        let newTask = Task<UIImage?, Never> {
            let client = Container.shared.currentUserSession()!.client

            guard let tileWidth = info.width else { return nil }

            let request = Paths.getTrickplayTileImage(
                itemID: itemID,
                width: tileWidth,
                index: tileImageIndex
            )
            guard let response = try? await client.send(request) else { return nil }
            let image = UIImage(data: response.value)!

            let secondsRangeStart = tileImageDuration * Double(tileImageIndex)
            let secondsRangeEnd = secondsRangeStart + tileImageDuration

            let trickplayImage = TrickplayImage(
                image: image,
                secondsRange: secondsRangeStart ... secondsRangeEnd,
                columns: columns,
                rows: rows,
                interval: Duration.milliseconds(interval)
            )

            self.images[tileImageIndex] = trickplayImage
            self.imageTasks[tileImageIndex] = nil
            return trickplayImage.image(for: seconds)
        }

        imageTasks[tileImageIndex] = newTask
        return await newTask.value
    }
}
