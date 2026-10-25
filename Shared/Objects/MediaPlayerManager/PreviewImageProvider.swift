//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import UIKit

@MainActor
final class PreviewImageProvider {

    private enum Source {

        case chapters([ChapterInfo.FullInfo])
        case trickplay(Trickplay)
    }

    private struct Trickplay {

        let columns: Int
        let rows: Int

        /// The pixel size of one thumbnail within a sheet.
        let tileSize: CGSize
        let interval: Duration
        let sheetURL: (Int) -> URL?

        var tilesPerSheet: Int {
            columns * rows
        }
    }

    private let source: Source
    private let resolveImage: (Int) async -> UIImage?

    init?(
        option: PreviewImageScrubbingOption,
        item: BaseItemDto,
        mediaSourceID: String?,
        chapters: [ChapterInfo.FullInfo],
        client: JellyfinClient,
        resolveImage: @escaping (Int) async -> UIImage?
    ) {
        // Chapters without any image would only scrub to black frames.
        let chapterSource = chapters.contains { $0.imageSource?.url != nil } ? Source.chapters(chapters) : nil

        let source: Source? = switch option {
        case .disabled:
            nil
        case .chapters:
            chapterSource
        case let .trickplay(fallbackToChapters):
            Self.trickplay(item: item, mediaSourceID: mediaSourceID, client: client).map(Source.trickplay)
                ?? (fallbackToChapters ? chapterSource : nil)
        }

        guard let source else { return nil }

        self.source = source
        self.resolveImage = resolveImage
    }

    /// The IDs to download ahead of scrubbing, in order, each resolved later by `image(for:)`.
    ///
    /// Trickplay doesn't say how many sheets exist, so its IDs are unbounded.
    var downloadIDs: AnySequence<Int> {
        switch source {
        case let .chapters(chapters):
            AnySequence(chapters.indices.filter { chapters[$0].imageSource?.url != nil })
        case .trickplay:
            AnySequence(0...)
        }
    }

    /// The remote image for a download ID.
    func downloadURL(for id: Int) -> URL? {
        switch source {
        case let .chapters(chapters):
            chapters[safe: id]?.imageSource?.url
        case let .trickplay(trickplay):
            id >= 0 ? trickplay.sheetURL(id) : nil
        }
    }

    func image(for seconds: Duration) async -> UIImage? {
        switch source {
        case let .chapters(chapters):
            guard let index = chapters.chapterIndex(at: seconds) else { return nil }

            return await resolveImage(index)

        case let .trickplay(trickplay):
            guard let thumbnail = Int(exactly: floor(max(.zero, seconds) / trickplay.interval)),
                  let sheet = await resolveImage(thumbnail / trickplay.tilesPerSheet)
            else { return nil }

            return sheet.getTileImage(
                index: thumbnail % trickplay.tilesPerSheet,
                columns: trickplay.columns,
                tileSize: trickplay.tileSize
            )
        }
    }

    private static func trickplay(item: BaseItemDto, mediaSourceID: String?, client: JellyfinClient) -> Trickplay? {
        guard let itemID = item.id, let mediaSourceID, let resolutions = item.trickplay?[mediaSourceID] else { return nil }

        for info in resolutions.values.sorted(by: { ($0.width ?? 0) < ($1.width ?? 0) }) {
            guard let width = info.width, width > 0,
                  let height = info.height, height > 0,
                  let columns = info.tileWidth, columns > 0,
                  let rows = info.tileHeight, rows > 0,
                  !columns.multipliedReportingOverflow(by: rows).overflow,
                  let milliseconds = info.interval, milliseconds > 0
            else { continue }

            return Trickplay(
                columns: columns,
                rows: rows,
                tileSize: CGSize(width: width, height: height),
                interval: .milliseconds(milliseconds),
                sheetURL: { sheet in
                    client.url(with: Paths.getTrickplayTileImage(
                        itemID: itemID,
                        width: width,
                        index: sheet,
                        mediaSourceID: mediaSourceID
                    ))
                }
            )
        }

        return nil
    }
}
