//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import SwiftUI

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
        let displayTitle: String
        let id: Int
        let imageSource: ImageSource
        let preferredPosterDisplayType: PosterDisplayType = .landscape
        let secondsRange: Range<Duration>
        let systemImage: String = "film"
        let unitRange: Range<Double>
        let unwrappedIDHashOrZero: Int

        var subtitle: String?
        var showTitle: Bool = true

        init(
            chapterInfo: ChapterInfo,
            imageSource: ImageSource,
            secondsRange: Range<Duration>,
            runtime: Duration
        ) {
            self.chapterInfo = chapterInfo
            self.imageSource = imageSource
            self.secondsRange = secondsRange
            self.unitRange = secondsRange.lowerBound / runtime ..< secondsRange.upperBound / runtime

            self.displayTitle = chapterInfo.displayTitle
            self.id = chapterInfo.hashValue
            self.unwrappedIDHashOrZero = id
        }

        func contains(seconds: Duration) -> Bool {
            secondsRange.contains(seconds)
        }

        func landscapeImageSources(maxWidth: CGFloat?, quality: Int?) -> [ImageSource] {
            [imageSource]
        }

        func transform(image: Image) -> some View {
            image
        }
    }
}
