//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Combine
import JellyfinAPI
import Stinsen
import SwiftUI
import VLCUI

extension ItemVideoPlayer.Overlay {

    struct TopBarView: View {

        @EnvironmentObject
        private var router: ItemVideoPlayerCoordinator.Router
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

                    Text(viewModel.item.displayTitle)
                        .font(.title3)
                        .fontWeight(.bold)
                        .lineLimit(1)
                        .alignmentGuide(.VideoPlayerTitleAlignmentGuide) { dimensions in
                            dimensions[.leading]
                        }

                    Spacer()

                    ItemVideoPlayer.Overlay.ActionButtons()
                }
                .font(.system(size: 24))
                .tint(Color.white)
                .foregroundColor(Color.white)
                
                if let subtitle = viewModel.item.subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(Color.gray)
                        .alignmentGuide(.VideoPlayerTitleAlignmentGuide) { dimensions in
                            dimensions[.leading]
                        }
                        .offset(y: -10)
                }
            }
        }
    }
}

extension HorizontalAlignment {
    struct VideoPlayerTitleAlignment: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            context[HorizontalAlignment.leading]
        }
    }

    static let VideoPlayerTitleAlignmentGuide = HorizontalAlignment(VideoPlayerTitleAlignment.self)
}
