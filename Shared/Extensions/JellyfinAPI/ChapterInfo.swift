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
        }

        func landscapeImageSources(
            environment: Empty
        ) -> [ImageSource] {
            [imageSource]
        }

        var posterLabel: some View {
            ChapterPosterLabel(chapter: self)
        }

        func posterOverlay(for displayType: PosterDisplayType) -> some View {
            PosterSelectionOverlay()
        }

        func transform(image: Image, displayType: PosterDisplayType) -> some View {
            ZStack {
                Color.black

                image
                    .aspectRatio(contentMode: .fit)
            }
        }
    }
}

private struct ChapterPosterLabel: View {

    let chapter: ChapterInfo.FullInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(chapter.chapterInfo.displayTitle)
                .font(.subheadline.weight(.semibold))
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .lineLimit(1)

            Text(chapter.chapterInfo.startSeconds ?? .zero, format: .runtime)
                .font(UIDevice.isTV ? .caption : .subheadline.weight(.semibold))
                .foregroundStyle(Color(UIColor.systemBlue))
                .padding(.horizontal, 4)
                .background {
                    Color(.darkGray)
                        .opacity(0.2)
                        .cornerRadius(4)
                }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
