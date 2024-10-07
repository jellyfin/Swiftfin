//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension VideoPlayer.Overlay {

    // TODO: rename `ChapterTrackMask`
    struct ChapterTrackMask: View {

//        @EnvironmentObject
//        private var viewModel: VideoPlayerViewModel

        @State
        private var width: CGFloat = 0

        private func maxWidth(for chapter: ChapterInfo.FullInfo) -> CGFloat {
            0
//            width * CGFloat(chapter.secondsRange.count) / CGFloat(viewModel.item.runTimeSeconds)
        }

        var body: some View {
            Color.white
//            HStack(spacing: 0) {
//                ForEach(viewModel.chapters, id: \.self) { chapter in
//                    HStack(spacing: 0) {
//                        if chapter != viewModel.chapters.first {
//                            Color.clear
//                                .frame(width: 1.5)
//                        }
//
//                        Color.white
//                    }
//                    .frame(maxWidth: maxWidth(for: chapter))
//                }
//            }
//            .frame(maxWidth: .infinity)
//            .onSizeChanged { newSize in
//                width = newSize.width
//            }
        }
    }
}
