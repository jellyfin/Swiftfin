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
        private var viewModel: ItemVideoPlayerViewModel
        
        init() {
            print("Top bar init-ed")
        }

//        let item: BaseItemDto
//        let eventSubject: CurrentValueSubject<VLCVideoPlayer.Event?, Never>
        
//        init(item: BaseItemDto, eventSubject: CurrentValueSubject<VLCVideoPlayer.Event?, Never>) {
//            self.item = item
//            self.eventSubject = eventSubject
//
//            print("top bar init-ed")
//        }
        
//        let item: BaseItemDto
//        let eventSubject: CurrentValueSubject<VLCVideoPlayer.Event?, Never>

        var body: some View {
            VStack(alignment: .EpisodeSeriesAlignmentGuide) {
                HStack(alignment: .center) {
                    Button {
                        viewModel.eventSubject.send(.cancel)
                        router.dismissCoordinator()
                    } label: {
                        Image(systemName: "xmark")
                            .padding()
                            .padding(.trailing, -10)
                    }

                    Text(viewModel.item.displayName)
                        .font(.title3)
                        .fontWeight(.bold)
                        .lineLimit(1)
                        .alignmentGuide(.EpisodeSeriesAlignmentGuide) { context in
                            context[.leading]
                        }

                    Spacer()

                    ItemVideoPlayer.Overlay.ActionButtons()
                        .padding(.leading, 100)
                }
                .font(.system(size: 24))
                .tint(Color.white)
                .foregroundColor(Color.white)

                if let subtitle = viewModel.item.subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(Color.gray)
                        .alignmentGuide(.EpisodeSeriesAlignmentGuide) { context in
                            context[.leading]
                        }
                        .offset(y: -18)
                }
            }
        }
        
//        static func == (
//            lhs: ItemVideoPlayer.Overlay.TopBarView,
//            rhs: ItemVideoPlayer.Overlay.TopBarView) -> Bool {
//                lhs.viewModel.isAspectFilled == rhs.viewModel.isAspectFilled
//        }
    }
}

//struct TopBarView_Previews: PreviewProvider {
//    static var previews: some View {
//        ZStack {
//            Color.red
//                .opacity(0.2)
//
//            VStack {
//                ItemVideoPlayer.Overlay.TopBarView(viewModel: .init(
//                    playbackURL: URL(string: "https://apple.com")!,
//                    item: .placeHolder,
//                    audioStreams: [],
//                    subtitleStreams: []))
//                .padding(.horizontal, 50)
//
//                Spacer()
//            }
//        }
//        .ignoresSafeArea()
//        .preferredColorScheme(.dark)
//        .previewInterfaceOrientation(.landscapeRight)
//    }
//}
