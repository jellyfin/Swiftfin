//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension VideoPlayer.PlaybackControls.PlaybackProgress {

    struct ChapterTrackMask: View {

        let chapters: [ChapterInfo.FullInfo]
        let runtime: Duration

        private var unitPoints: [Double] {
            chapters.map { chapter in
                guard let startSeconds = chapter.chapterInfo.startSeconds,
                      startSeconds < runtime
                else {
                    return 0
                }

                return startSeconds / runtime
            }
        }

        var body: some View {
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    ForEach(unitPoints, id: \.self) { unitPoint in
                        if unitPoint > 0 {
                            Color.black
                                .frame(width: 1.5)
                                .offset(x: proxy.size.width * unitPoint - 0.75)
                        }
                    }
                }
            }
        }
    }
}
