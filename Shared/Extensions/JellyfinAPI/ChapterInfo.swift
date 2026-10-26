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
        let imageSource: ImageSource?
        let preferredPosterDisplayType: PosterDisplayType = .landscape
        let systemImage: String = "film"

        var subtitle: String?

        init(
            chapterInfo: ChapterInfo,
            imageSource: ImageSource? = nil
        ) {
            self.chapterInfo = chapterInfo
            self.displayTitle = chapterInfo.displayTitle
            self.id = chapterInfo.hashValue
            self.imageSource = imageSource
        }

        func imageSources(
            for displayType: PosterDisplayType,
            environment: Empty
        ) -> [ImageSource] {
            if displayType == .landscape {
                imageSource
            }
        }

        var posterLabel: some View {
            ChapterPosterLabel(chapter: self)
        }

        func posterAccessibility(configuration: PosterConfiguration) -> PosterAccessibility {
            let startTime = PosterAccessibility.duration(chapterInfo.startSeconds ?? .zero)
            return PosterAccessibility(
                label: displayTitle,
                value: L10n.posterAccessibilityStartTime(startTime)
            )
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

extension [ChapterInfo.FullInfo] {

    /// The start time of the first chapter that begins after the given time, if any.
    func nextChapterStart(after seconds: Duration) -> Duration? {
        lazy
            .compactMap(\.chapterInfo.startSeconds)
            .first(where: { $0 > seconds })
    }

    /// The start time to skip back to from the given time: the current
    /// chapter's start when more than 3 seconds into it, otherwise the
    /// previous chapter's start.
    func previousChapterStart(before seconds: Duration) -> Duration? {
        let starts = compactMap(\.chapterInfo.startSeconds)

        guard let currentIndex = starts.lastIndex(where: { $0 <= seconds }) else {
            return starts.first
        }

        if seconds - starts[currentIndex] > .seconds(3) {
            return starts[currentIndex]
        }

        return currentIndex > 0 ? starts[currentIndex - 1] : starts[currentIndex]
    }
}

// TODO: have label match what BaseItemDto does in PosterCollectionView
//       - different height, causes clipping

private struct ChapterPosterLabel: View {

    let chapter: ChapterInfo.FullInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(chapter.chapterInfo.displayTitle)
                .font(.subheadline)
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
