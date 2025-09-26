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

    var startSeconds: Duration? {
        guard let startPositionTicks else { return nil }
        return Duration.ticks(startPositionTicks)
    }
}

extension ChapterInfo {

    struct FullInfo: Poster {

        let chapterInfo: ChapterInfo
        let imageSource: ImageSource
        let systemImage: String = "film"

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
            imageSource: ImageSource
        ) {
            self.chapterInfo = chapterInfo
            self.imageSource = imageSource
        }

        func landscapeImageSources(maxWidth: CGFloat?, quality: Int?) -> [ImageSource] {
            [imageSource]
        }
    }
}
