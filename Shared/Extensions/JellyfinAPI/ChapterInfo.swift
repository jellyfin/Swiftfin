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

    var startTimeSeconds: TimeInterval {
        TimeInterval(startPositionTicks ?? 0) / 10_000_000
    }
}

extension ChapterInfo {

    struct FullInfo: Poster {

        let chapterInfo: ChapterInfo
        let imageSource: ImageSource
        let secondsRange: Range<TimeInterval>
        let systemImage: String = "film"
        let unitRange: Range<Double>

        var displayTitle: String {
            chapterInfo.displayTitle
        }

        var id: Int {
            chapterInfo.hashValue
        }

        var unwrappedIDHashOrZero: Int {
            id
        }

        var subtitle: String?
        var showTitle: Bool = true

        init(
            chapterInfo: ChapterInfo,
            imageSource: ImageSource,
            secondsRange: Range<TimeInterval>,
            runtimeSeconds: TimeInterval
        ) {
            self.chapterInfo = chapterInfo
            self.imageSource = imageSource
            self.secondsRange = secondsRange
            self.unitRange = secondsRange.lowerBound / runtimeSeconds ..< secondsRange.upperBound / runtimeSeconds
        }

        func landscapeImageSources(maxWidth: CGFloat?) -> [ImageSource] {
            [imageSource]
        }
    }
}
