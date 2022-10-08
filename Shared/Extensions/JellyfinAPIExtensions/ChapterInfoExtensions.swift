//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

extension ChapterInfo {

    var timestampLabel: String {
        let seconds = (startPositionTicks ?? 0) / 10_000_000
        return seconds.toReadableString()
    }

    var startTimeSeconds: Int {
        let playbackPositionTicks = startPositionTicks ?? 0
        return Int(playbackPositionTicks / 10_000_000)
    }
}

extension ChapterInfo: Displayable {

    var displayName: String {
        name ?? .emptyDash
    }
}

extension ChapterInfo {

    struct FullInfo: Poster, Equatable {

        let chapterInfo: ChapterInfo
        let imageSource: ImageSource
        let secondsRange: Range<Int>

        init(
            chapterInfo: ChapterInfo,
            imageSource: ImageSource,
            secondsRange: Range<Int>
        ) {
            self.chapterInfo = chapterInfo
            self.imageSource = imageSource
            self.secondsRange = secondsRange
        }

        var displayName: String {
            chapterInfo.displayName
        }

        var subtitle: String?
        var showTitle: Bool = true

        func portraitPosterImageSource(maxWidth: CGFloat) -> ImageSource {
            .init()
        }

        func landscapePosterImageSources(maxWidth: CGFloat, single: Bool) -> [ImageSource] {
            [imageSource]
        }
    }
}
