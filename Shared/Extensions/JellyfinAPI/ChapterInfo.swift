//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
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

    // TODO: possibly remove
    //       - have ChapterInfo: Poster
    //       - build info, ImageSource pairs where required
    struct FullInfo: Poster {

        let chapterInfo: ChapterInfo
        let displayTitle: String
        let id: Int
        let imageSource: ImageSource
        let preferredPosterDisplayType: PosterDisplayType = .landscape
        let systemImage: String = "film"
        let unwrappedIDHashOrZero: Int

        var subtitle: String?
        var showTitle: Bool = true

        init(
            chapterInfo: ChapterInfo,
            imageSource: ImageSource
        ) {
            self.chapterInfo = chapterInfo
            self.displayTitle = chapterInfo.displayTitle
            self.id = chapterInfo.hashValue
            self.imageSource = imageSource
            self.unwrappedIDHashOrZero = chapterInfo.hashValue
        }

        func landscapeImageSources(maxWidth: CGFloat?, quality: Int?) -> [ImageSource] {
            [imageSource]
        }

        func transform(image: Image) -> some View {
            ZStack {
                Color.black

                image
                    .aspectRatio(contentMode: .fit)
            }
        }
    }
}
