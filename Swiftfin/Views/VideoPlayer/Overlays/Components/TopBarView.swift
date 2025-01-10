//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import Stinsen
import SwiftUI
import VLCUI

extension VideoPlayer.Overlay {

    struct TopBarView: View {

        @EnvironmentObject
        private var router: VideoPlayerCoordinator.Router
        @EnvironmentObject
        private var splitContentViewProxy: SplitContentViewProxy
        @EnvironmentObject
        private var videoPlayerProxy: VLCVideoPlayer.Proxy
        @EnvironmentObject
        private var viewModel: VideoPlayerViewModel

        var body: some View {
            VStack(alignment: .VideoPlayerTitleAlignmentGuide, spacing: 0) {
                HStack(alignment: .center) {
                    Button {
                        videoPlayerProxy.stop()
                        router.dismissCoordinator()
                    } label: {
                        Image(systemName: "xmark")
                            .padding()
                    }
                    .contentShape(Rectangle())
                    .buttonStyle(ScalingButtonStyle(scale: 0.8))

                    Text(viewModel.item.displayTitle)
                        .font(.title3)
                        .fontWeight(.bold)
                        .lineLimit(1)
                        .alignmentGuide(.VideoPlayerTitleAlignmentGuide) { dimensions in
                            dimensions[.leading]
                        }

                    Spacer()

                    VideoPlayer.Overlay.BarActionButtons()
                        .buttonStyle(ScalingButtonStyle(scale: 0.8))
                }
                .font(.system(size: 24))
                .tint(Color.white)
                .foregroundColor(Color.white)

//                if let subtitle = viewModel.item.subtitle {
//                    Text(subtitle)
//                        .font(.subheadline)
//                        .foregroundColor(.white)
//                        .alignmentGuide(.VideoPlayerTitleAlignmentGuide) { dimensions in
//                            dimensions[.leading]
//                        }
//                        .offset(y: -10)
//                }
            }
        }
    }
}
