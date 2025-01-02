//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

extension ChapterInfo: Displayable {

    var displayTitle: String {
        name ?? .emptyDash
    }
}

extension ChapterInfo {

    var timestampLabel: String {
        let seconds = (startPositionTicks ?? 0) / 10_000_000
        return seconds.timeLabel
    }

    var startTimeSeconds: Int {
        let playbackPositionTicks = startPositionTicks ?? 0
        return Int(playbackPositionTicks / 10_000_000)
    }
}

extension ChapterInfo {

    struct FullInfo: Poster, Equatable {

        var id: Int {
            chapterInfo.hashValue
        }

        let chapterInfo: ChapterInfo
        let imageSource: ImageSource
        let secondsRange: Range<Int>

        var displayTitle: String {
            chapterInfo.displayTitle
        }

        var unwrappedIDHashOrZero: Int {
            id
        }

        let systemImage: String = "film"
        var subtitle: String?
        var showTitle: Bool = true

        init(
            chapterInfo: ChapterInfo,
            imageSource: ImageSource,
            secondsRange: Range<Int>
        ) {
            self.chapterInfo = chapterInfo
            self.imageSource = imageSource
            self.secondsRange = secondsRange
        }

        func landscapeImageSources(maxWidth: CGFloat?) -> [ImageSource] {
            [imageSource]
        }
    }
}
